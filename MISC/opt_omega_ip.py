#!/usr/bin/env python
import os
import sys
import abinitio_driver as driver
from abinitio_driver import AUtoEV
import scipy.optimize as opt
from scipy.interpolate  import interp1d
try:
   import matplotlib
   matplotlib.use('Agg')
   import matplotlib.pyplot as plt
except:
   pass

# This is the driver script for omega tuning of long-range functionals such as BNL or wPBE
# The interface to ab initio programs is in separate file abinitio_driver.py
# and currently supports QCHEM and TeraChem

# Initial input files for ground and ionized state should be in files:
# optomega_gs.inp and optomega_is.inp
# This file can be directly submitted to the queue


####### USER INPUT PARAMETERS ############################

#PROGRAM = "QCHEM"
PROGRAM = "TERACHEM"
METHOD = 0
# 0 - minimization
# 1 - interpolation
# 2 - read omega-deltaIP function from file omegas.dat and interpolate

# Options for interpolation
MIN_OMEGA =  300
BEST_GUESS = 400
MAX_OMEGA =  500
STEP      =  50
# for interpolation, one needs at least 2 starting points
# i.e. (MAX_OMEGA-MIN_OMEGA)/STEP >=2
# of course, this inequality should hold as well: MIN_OMEGA <  BEST_GUESS < MAX_OMEGA

# OPTIONS for minimizer
# accuracy and maximum iterations for the minimizer
THR_OMEGA = 10.000  # absolute accuracy, omega*1000
MAXITER   = 20
# These are bounds for the minimizer, can be tighter if you know where to look
MIN_OMEGA_DEF = 100
MAX_OMEGA_DEF = 800

####### END OF USER INPUT #########################################

# Whether to check SCF convergence (implemented only for TC at the moment)
driver.CHECK_SCF = True

if BEST_GUESS <= MIN_OMEGA or BEST_GUESS >= MAX_OMEGA:
   print("ERROR:Incorrect input value for BEST_GUESS")
   sys.exit(1)

if METHOD == 1 and (MAX_OMEGA-MIN_OMEGA)/STEP < 1:
    print("ERROR: Wrong initial interpolation interval. I need at least 2 initial points")
    print("Adjust MIN_OMEGA or MAX_OMEGA or STEP")
    sys.exit(1)


def minimize(min_omega, max_omega, thr_omega):
   """Minimization of a general univariate function"""
   # http://docs.scipy.org/doc/scipy/reference/optimize.html
   try:
      res = opt.minimize_scalar(f_optomega_ip,method="bounded",bounds=(MIN_OMEGA_DEF, MAX_OMEGA_DEF), \
              options={"xatol":thr_omega,"maxiter": MAXITER,"disp": True})
   except NameError:
       print("Whoops, you probably have old version of SciPy that does not have minimize_scalar!")
       print("Use interpolation instead and comment out this code!")
       raise

   print(res)
   if "success" in res:
      suc = res.success # older scipy versions do not have this attribute
   else:
      suc = True 

   if suc == True:
      return res.x
   else:
      print("Minimization probably did not converge! Check results carefully.")
      sys.exit(2)

def f_optomega_ip(omega):
   if PROGRAM == "TERACHEM":
      dr = driver.Abinitio_driver_terachem()
   elif PROGRAM == "QCHEM":
      dr = driver.Abinitio_driver_qchem()

   IP_dscf, IP_koop = dr.compute_ip(omega/1000.)

   f = (IP_dscf - IP_koop)**2
   return f


def interpolate(min_omega, max_omega, step, best_guess):
   """Interpolate for fixed omega range using cubic spline
        Then find the root."""
   omega = min_omega
   if PROGRAM == "TERACHEM":
      driver = driver.Abinitio_driver_terachem()
   elif PROGRAM == "QCHEM":
      driver = driver.Abinitio_driver_qchem()
    
   deltaIP = []
   omegas  = []
   # Initial points for interpolation, determined by the user via MAX_OMEGA, MIN_OMEGA and STEP
   while omega <= max_omega:
      IP_dscf, IP_koop = driver.compute_ip(omega/1000.)
      deltaIP.append(IP_dscf-IP_koop)
      omegas.append(omega)
      omega += step

#  Check whether deltaIP crosses zero
#  If not, extend the interpolation interval
#  This assumes a monotonic dependence of deltaIP on omega
   while deltaIP[0] * deltaIP[-1] > 0:
      if (deltaIP[-1] < deltaIP[-2] and deltaIP[-1] > 0) \
              or (deltaIP[-1] > deltaIP[-2] and deltaIP[-1] < 0):
        best_guess = omegas[-1] + step / 2.0
        omega = omegas[-1] + step
        omegas.append(omega)
        IP_dscf, IP_koop = driver.compute_ip(omega/1000.)
        deltaIP.append(IP_dscf-IP_koop)
      else:
        best_guess = omegas[0] - step / 2.0
        omega = omegas[0] - step
        omegas.insert(0,omega)
        IP_dscf, IP_koop = driver.compute_ip(omega/1000.)
        deltaIP.insert(0,IP_dscf-IP_koop)
      

   # Interpolate the computed points
   if len(omegas) >=4:
       f_omega = interp1d(omegas, deltaIP, kind='cubic')
   elif len(omegas) == 3:
       f_omega = interp1d(omegas, deltaIP, kind='quadratic')
   elif len(omegas) == 2:
       f_omega = interp1d(omegas, deltaIP, kind='linear')
   else:
       print("ERROR: I need at least 2 points for interpolation, and I only got "+str(len(omegas)))
       sys.exit(1)

   # Plot the interpolated function for later inspection
   try:
      x = [ x + omegas[0] for x in range((omegas[-1]-omegas[0]))]
      plt.plot(omegas, deltaIP, 'o', x, f_omega(x), "-")
      plt.savefig("omega-deltaIP.png")
   except:
      pass

   # Find the root of interpolated function deltaIP(omega)
   # Brent method should be superior to newton
   # It is also guaranteed not to step out of a given interval,
   # which is crucial here, since f_omega function throws an exception in that case
   res = opt.brentq(f_omega, omegas[0], omegas[-1])
   return res


def interpolate_read(min_omega, max_omega, step, best_guess):
   """Interpolate for fixed omega range using cubic spline
        Then find the root. Read omegas from s file"""
    
   deltaIP = []
   omegas  = []

   with open("omegas.dat","r") as f:
      comm_first = True
      for line in f:
         l = line.split()
         if not len(l):
            continue
         if l[0][0] == '#':
            if comm_first:
               comm_first = False
               continue
            else:
               break
         else:
            omegas.append(float(l[0]))
            deltaIP.append(float(l[1]))

#  Check whether deltaIP crosses zero. If not, exit
#  This assumes a monotonic dependence of deltaIP on omega
   if deltaIP[0] * deltaIP[-1] > 0:
      print("ERROR:could not find optimal omega for a computed range.")
      sys.exit(1)

   # Interpolate the computed points
   if len(omegas) >=4:
       f_omega = interp1d(omegas, deltaIP, kind='cubic')
   elif len(omegas) == 3:
       f_omega = interp1d(omegas, deltaIP, kind='quadratic')
   elif len(omegas) == 2:
       f_omega = interp1d(omegas, deltaIP, kind='linear')
   else:
       print("ERROR: I need at least 2 points for interpolation, and I only got "+str(len(omegas)))
       sys.exit(1)

   # Plot the interpolated function for later inspection
   try:
      x = [ x + omegas[0] for x in range((omegas[-1]-omegas[0]))]
      plt.plot(omegas, deltaIP, 'o', x, f_omega(x), "-")
      plt.savefig("omega-deltaIP.png")
   except:
      pass

   # Find the root of interpolated function deltaIP(omega)
   res = opt.brentq(f_omega, omegas[0], omegas[-1])
   return res


#### Actual calculation starts here!

if METHOD == 0:
    omega = minimize(MIN_OMEGA, MAX_OMEGA, THR_OMEGA)
elif METHOD == 1:
    omega = interpolate(MIN_OMEGA, MAX_OMEGA, STEP, BEST_GUESS)
elif METHOD == 2:
    omega = interpolate_read(MIN_OMEGA, MAX_OMEGA, STEP, BEST_GUESS)

print("Final tuned omega = ",omega)

if METHOD == 2:
   sys.exit(0)

# This can be skipped if you want to save time
print("Recomputing with final omega...")

if PROGRAM == "TERACHEM":
    dr = driver.Abinitio_driver_terachem()
if PROGRAM == "QCHEM":
    dr = driver.Abinitio_driver_qchem()

IP_dscf, IP_koop = dr.compute_ip(omega/1000.)
err   = IP_dscf - IP_koop
print("Final IP_dscf:",IP_dscf*AUtoEV)
print("Final IP_koop:",IP_koop*AUtoEV)
print("Final deltaIP:",err*AUtoEV)
    
