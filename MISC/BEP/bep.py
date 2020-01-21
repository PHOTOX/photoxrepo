#!/usr/bin/env python3

# Implementation of BEP model, see:
# Binary-encounter-dipole model for electron-impact ionization
# Kim, Yong Ki, Rudd, M. Eugene Phys Rev A, 1994, 5, 3954-3967

# Cross sections for K-shell ionization of atoms by electron impact
# Santos, J P, Parente, F, Kim, Y-k, Journal of Physics B: Atomic, Molecular and Optical Physics, 2003

# WARNING: Currrent implementation works only for closed shell molecules!

# A very simple model valid only for atoms from Talukder et al is alson implemented
# Empirical model for electron impact ionization cross sections
# M.R. Talukder et al The European Physical Journal D 46, 281-287, 2008

import math, re, sys
import argparse

AU2EV = 27.2114
ANG2BOHR = 1.889726132873

def read_cmd():
   """Reading from command line"""
   desc = "Binary Encounter Bethe (BEB) model:\n   \
         electron impact photoionization cross section from first principles"
   parser = argparse.ArgumentParser(description=desc)
   parser.add_argument("-i", "--input_file", dest="inp_file", help="Gaussian output file with MO parameters.")
   parser.add_argument("-m", "--model", dest="model",default="bep", help="Which model? (bep|talukder).")
   parser.add_argument("-U", dest="U", type=float, help="electron orbital kinetic energy [ev]")
   parser.add_argument("--Tmax", dest="Tmax", type=float, default=1000., help="maximum kin. energy of ionizing electron [ev]")
   parser.add_argument("-T", dest="T",type=float, help="kinetic energy [ev] of the ionizing electron")
   parser.add_argument("-B", dest="B",type=float, help="electron binding energy [ev]")
   parser.add_argument("-N", dest="N",type=int, default=2, help="number of eletrons in the orbital")
   parser.add_argument("-n", dest="n",type=int, help="Talukder model, principal quantum number")
   parser.add_argument("-l", dest="l",type=int, help="Talukder model, azimuthal quantum number")
   parser.add_argument("-c", "--charge", dest="charge",type=int, default=0, help="Charge")
   return parser.parse_args()

def bep_cross_section(T, B, U, N, charge):
   """Calculates electron impact ionization cross section for a given MO.
      Input params should be in atomic units!
      T = kinetic energy of ionizing electron
      B = electron binding energy (VIE)
      U = orbital kinetic energy
      N = electron occupation number of a given orbital"""

   a0 = 1  # Bohr radius [au]
   R = 0.5 # Rydberg energy [au]
   t = T / B
   u = U / B

   denom = 1
   if (charge == 1):
      #modification for singly charged ions, see
      # Electron-Impact lonization Cross Sections for Polyatomic Molecules, Radicals, and Ions
      # Kim, Yong-Ki,Irikura, Karl K
      # Section 2.2
      denom = 2

   S = 4 * math.pi * a0**2 * N * (R/B)**2

   x1 = S / (t + (u + 1)/denom)
   x2 = math.log(t) / 2 * (1 - 1 / t**2)
   x3 = 1 - 1/t - math.log(t)/(1+t)
   sigma_BEB = x1 * (x2 + x3)
   return sigma_BEB


def talukder_Anl(B, n, l):
   """Implements equations 3 on page 282
   B = ionization energy
   n = principal quantum number
   l = azimuthal quantum number"""
   R = 0.5 # Rydberg energy in Atomic units
   Ur = B / R
   if n == 1:
      if l == 0:
         Anl = 3.97 * 10**(-11) * Ur / (1+20.74*Ur)**(3.6)    
      else:
         Anl = 3.88 * 10**(-14) * Ur / (1+6.96*Ur)**3
   else:
      if l == 0:
         Anl = 9.14*10**(-11)*Ur / (1+68.32*Ur)**3
      else:
         Anl = 1.22 * 10**(-6) * Ur / (1+566.46*Ur)**(3.5)

   # Convert from cm**2 to atomic units
   return Anl * 10**16 * ANG2BOHR**2 


def talukder_Bnl(B, n, l):
   """Implements equations 3 on page 282
   B = ionization energy
   n principal quantum number
   l = azimuthal quantum number"""
   R = 0.5 # Rydberg energy in Atomic units
   Ur = B / R
   if n == 1:
      if l == 0:
         Bnl = 2.29 * 10**(-10) * Ur / (1+39.9*Ur)**(3.6)    
      else:
         Bnl = 4.36 * 10**(-16) * Ur / (1+0.33*Ur)**8
   else:
      if l == 0:
         Bnl = 3.83 * 10**(-11) * Ur / (1+60.95*Ur)**3    
      else:
         Bnl = - 4.39 * 10**(-9) * Ur / (1+102.87*Ur)**3.7

   # Convert from cm**2 to atomic units
   return Bnl * 10**16 * ANG2BOHR**2 


def talukder_cross_section(T, B, n, l, N):
   """Calculates electron impact ionization cross section for a given MO.
   based on simple model of Talukder et al
   Input params should be in atomic units!
      T = kinetic energy of ionizing electron
      B = electron binding energies of atomic orbitals (VIE)
      N = electron occupation number of a given orbital"""

#  for n in range(1,8):
#     for l in range(n):
#        for i in range(2*l+1):
   Anl = talukder_Anl(B, n, l)
   Bnl = talukder_Bnl(B, n, l)
   sigma = Anl*math.log(T/B)+Bnl*(1-B/T)
   sigma = sigma * B * N / T
   return sigma


def parse_gaussian(infile, E_orb, Ekin_orb):
   """Parses Gaussian output and extracts
      MO binding energies and MO kinetic energies"""
   # This needs to be matched
   # Orbital energies and kinetic energies (alpha):
   # 1         O               -19.001985         29.005918
   start_line = ' Orbital energies and kinetic energies (alpha):\n'
   dec = r' +-?\d+\.\d+'  # regex matching decimal numbers
   reg = re.compile(r'^ +[0-9]+ +O'+dec+dec+r'$')
   with open(infile,"r") as f:
      read = False
      for line in f:
         # This is because of false positives in the beginning of log file
         # i.e. we do not want to match oxygen atom in Z-matrix
         if line == start_line:
            read = True
         res = reg.search(line)
         if res and read:
            E_orb.append(-float(line.split()[2]))
            Ekin_orb.append(float(line.split()[3]))

   # Print the parsed value for the user to check
   print("# MO binding energies read from G09 output")
   print("#", E_orb)
   print("# MO kinetic energies read from G09 output")
   print("#", Ekin_orb)


if __name__ == "__main__":

   help_me = "Use \"-h\" to get help"
   opts = read_cmd()

   # Let's try H2+
   #B = 30 / AU2EV
   #U = 16.4 / AU2EV
   #N = 1
   #charge = +1

   # neutral H2
   #B = 15.43 / AU2EV
   #U = 15.98 / AU2EV
   #N = 2
   #charge = 0

   Ekin = []
   Eorb = []

   if not opts.inp_file and (not opts.B and not opts.U):
      print("ERROR: You did not provide Gaussian output file as a parameter")
      print("Alternatively, you could provide B and U parameters")
      print(help_me)
      sys.exit(1)

   if opts.inp_file:
      parse_gaussian(opts.inp_file, Eorb, Ekin)
   else:
      Eorb.append(opts.B / AU2EV)
      Ekin.append(opts.U / AU2EV)

   N = opts.N
   if opts.charge != 0 and opts.charge != 1:
      print("ERROR: Charge must be 0 or 1, other values are not supported!")
      sys.exit(1)

   Ts = []  # Calculate cross sections for these incident kinetic energies
   if opts.T:
      Ts.append(opts.T / AU2EV)
   else:
      Ts = [x/AU2EV for x in range(int(Eorb[-1]*AU2EV), int(opts.Tmax) ) ]

   print("# Incident electron energy [eV] | Total Sigma | Sigmas [Angstrom^2] (core electrons first)")
   for t in Ts:
      sigma = []
      total_sigma = 0
      if opts.n and opts.l:
         n = opts.n
         l = opts.l
         m_l = -l
      else:
         n = 1
         l = 0
         m_l = 0
      # Iterate over orbitals
      for i in range(len(Eorb)):
         if Eorb[i] <= t:
            if opts.model == "bep":
               s = bep_cross_section(t, Eorb[i], Ekin[i], N, opts.charge)
            elif opts.model == "talukder":
               s = talukder_cross_section(t, Eorb[i], n, l, N)
            else:
               print("ERROR: Invalid model!")
               print(help_me)
               sys.exit(1)
         else:
            s = 0

         sigma.append(s / ANG2BOHR / ANG2BOHR)
         total_sigma += sigma[-1]

         # Aufbau principle (needed for Talukber model)
         if m_l == l:
             l += 1
             m_l = -l
         else:
             m_l += 1
         if l == n:
             l = 0
             n += 1
             m_l = 0

      print(t*AU2EV, total_sigma, " ".join(str(s) for s in sigma))


