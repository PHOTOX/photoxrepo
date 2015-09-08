#!/usr/bin/python
from __future__ import division
import math
import sys

# TODO:
# 1. command line input
# 2. Gaussian and Lorentzian broadening

####command line parameters
# -b    number_in_ev #probably non needed
# -e    number_in_ev # probably not needed
# -de   resolution of the spectra
# -inp  filename with input data
#  --notrans   no intensities, normalize spectrum to unity
#  -eps --epsilon    intensities in molar exctinction coef.
# -nsamp  number of samples

#  --smooth (perform runnning average?)

# Some constants
EVtoJ = 1.602e-19
EPS = 8.854e-12
HPRIME = 6.626e-34/(2*math.pi)
C = 299792e3
DEB = 2.5*3.34e-30

class Spectrum(object):

   def __init__(self, nsample, deltaE, notrans):
      self.trans = []
      self.intensity = []
      self.exc = []
      self.maxe = 0.0
      self.nsample = nsample
      self.notrans = False
      self.de = deltaE # in eV
      if notrans == True:
         self.notrans = True

   def trans2intensity(self):
      for j in range(int( self.maxe/self.de )):
         self.intensity.append(0)

      for i in range(len(self.trans)):

         index = int( (self.maxe-self.exc[i]) / self.de )
         self.trans2 = self.trans[i][0]**2 + self.trans[i][1]**2 + self.trans[i][2]**2
         self.trans2 *= math.pi*self.exc[i]/(3*HPRIME*EPS*C*self.de)
         self.trans2 *= DEB * DEB * 1e4 / self.nsample
         self.intensity[index] += self.trans2

   def normalize(self):
      for j in range(int( self.maxe/self.de )):
         self.intensity.append(0.0)

      for i in range(len(self.exc)):
         index = int( (self.maxe-self.exc[i]) / self.de )
         self.intensity[index] += 1.0 / self.nsample / self.de


   def read_data(self, infile):
      f = open(infile, "r") 
      i = 0
      with open(infile, "r") as f:
         for line in f:
            if i % 2 == 1 and self.notrans == False:
               self.trans.append( line.split() )
               if len(self.trans[-1]) != 3:
                  print("Error: Corrupted line "+str(i+1)+" in file "+filename)
                  print("Expected 3 columns of transition dipole moments, got:")
                  print(line)
                  sys.exit(1)
               self.trans[-1][0] = float( self.trans[-1][0] )
               self.trans[-1][1] = float( self.trans[-1][1] )
               self.trans[-1][2] = float( self.trans[-1][2] )
            else:
               # TODO: test, that we have type string and not list
               self.exc.append(float( line ))

            i += 1

      self.maxe = max(self.exc)+3.0
      if self.notrans == True:
         self.normalize()
      else:
         self.trans2intensity()

      f.close()

   def writeout(self, unit, fileout):
      self.units = {}
      self.units['nm'] = 1239.8
      self.units['ev'] = 1.
      self.units['cm'] = 8065.7
      f = open(fileout, "w") 

      for i in range(len(self.intensity)):
         self.energy = (self.maxe-i*de)
         if unit == "nm":
            if self.units[unit]/self.energy < 1000:
              f.write('%f %e \n' % (self.units[unit]/self.energy, self.intensity[i]))
         else:
            f.write('%f %e \n' % (self.energy*self.units[unit], self.intensity[i]))

      f.close()


   def cross2eps(self):
      pass


class SpectrumBroad(Spectrum):

   def __init__(self, nsample, de, sigma, tau):
      self.trans = []
      self.exc = []
      self.epsilon = epsilon
      self.sigma = sigma
      self.nsample = nsample
      self.notrans = False
      self.de = deltaE # in eV
      if notrans == True:
         self.notrans = True

   def gauss():
      pass

   def lorentz():
      pass



def read_cmd(nsample, de, sigma, tau, eps, notrans, filename):
   pass


tau = 0
sigma = 0
de = 0.02 #energy resolution in eV
nsample = 2
#filename = "specdata.dat"
filename = "ion.dat"
notrans = True
eps = False

if tau > 0 or sigma > 0:
   spectrum = SpectrumBroad(nsample, de, sigma, tau, notrans)
else:
   spectrum = Spectrum(nsample, de, notrans)

spectrum.read_data(filename)

spectrum.writeout("nm", "spectrum.nm."+str(nsample)+".dat") 
spectrum.writeout("ev", "spectrum.ev."+str(nsample)+".dat") 
spectrum.writeout("cm", "spectrum.cm."+str(nsample)+".dat") 

