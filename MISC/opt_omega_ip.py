#!/usr/bin/env python
import os
import sys
from abinitio_driver import *
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
#PROGRAM = "TERACHEM"
PROGRAM = "TERACHEM"
METHOD = 1
# 0 - minimization
# 1 - interpolation
MIN_OMEGA =  350
BEST_GUESS = 450
MAX_OMEGA =  500
STEP      =  50
# for interpolation, one needs at least 2 starting points
# i.e. (MAX_OMEGA-MIN_OMEGA)/STEP >=2
# of course, this inequality should hold as well: MIN_OMEGA <  BEST_GUESS < MAX_OMEGA

# accuracy and maximum iterations for the minimizer
THR_OMEGA = 0.005
MAXITER   = 20

####### END OF USER INPUT #########################################

# use only if you already have output files and you know what you're doing!
DRY_RUN = False

# These 2 are a safety defaults for the minimizer
# if the user picked MIN_OMEGA, BEST_GUESS and MAX_OMEGA incorrectly
MIN_OMEGA_DEF = 100
MAX_OMEGA_DEF = 800


if BEST_GUESS <= MIN_OMEGA or BEST_GUESS >= MAX_OMEGA:
   print("ERROR:Incorrect input value for BEST_GUESS")
   sys.exit(1)

if METHOD == 1 and (MAX_OMEGA-MIN_OMEGA)/STEP < 2:
    print("ERROR: Wrong initial interpolation interval. I need at least 2 initial points")
    print("Adjust MIN_OMEGA or MAX_OMEGA or STEP")
    sys.exit(1)


def minimize(min_omega, max_omega, thr_omega):
   """Minimization of a general univariate function"""
   # http://docs.scipy.org/doc/scipy/reference/optimize.html
   try:
      res  = opt.minimize_scalar(f_optomega_ip,method="brent",bracket=(MIN_OMEGA, BEST_GUESS, MAX_OMEGA), \
         options={"xtol":thr_omega,"maxiter": MAXITER})
   except ValueError as e:
       print(e)
       print("Using bracketing interval:",MIN_OMEGA_DEF, MAX_OMEGA_DEF)
       res = opt.minimize_scalar(f_optomega_ip,method="brent",bracket=(MIN_OMEGA_DEF, MAX_OMEGA_DEF), \
            options={"xtol":thr_omega,"maxiter": MAXITER})
   except NameError:
       print("Whoops, you probably have old version of SciPy that does not have minimize_scalar!")
       print("But you can comment the following line and use interpolation instead!")
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
      driver = Abinitio_driver_terachem()
   elif PROGRAM == "QCHEM":
      driver = Abinitio_driver_qchem()

   IP_dscf, IP_koop = driver.compute_ip(omega/1000.)

   f = (IP_dscf - IP_koop)**2
   return f


def interpolate(min_omega, max_omega, step, best_guess):
   """Interpolate for fixed omega range using cubic spline
        Then find the root."""
   omega = min_omega
   if PROGRAM == "TERACHEM":
      driver = Abinitio_driver_terachem()
   elif PROGRAM == "QCHEM":
      driver = Abinitio_driver_qchem()
    
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


#### Actual calculation starts here!

if METHOD == 0:
    omega = minimize(MIN_OMEGA, MAX_OMEGA, THR_OMEGA)
elif METHOD == 1:
    omega = interpolate(MIN_OMEGA, MAX_OMEGA, STEP, BEST_GUESS)

print("Final tuned omega = ",omega)
print("Recomputing with final omega...")

if PROGRAM == "TERACHEM":
    driver = Abinitio_driver_terachem()
if PROGRAM == "QCHEM":
    driver = Abinitio_driver_qchem()

IP_dscf, IP_koop = driver.compute_ip(omega/1000.)
print("Final IP_dscf:",IP_dscf*AUtoEV)
print("Final IP_koop:",IP_koop*AUtoEV)
    

