#!/usr/bin/env python
from __future__ import division
from optparse import OptionParser
import math
import sys

# TODO:
# 1. Gaussian and Lorentzian broadening

def read_cmd():
   """Function for reading command line options. Returns tuple options, args."""
   usage = "usage: %prog [options] input_file"
   parser = OptionParser(usage)
   parser.add_option('-n','--nsample',dest='nsample', type='int', default=1, help='Number of samples.')
   parser.add_option('-d','--de',dest='de', type='float', default=0.02, help='Bin step in eV. Default = 0.02 ')
#   parser.add_option('-s','--sigma',dest='sigma', default=0.0, help='Parameter for Gaussian broadening.')
#   parser.add_option('-t','--tau',dest='tau', help='Parameter for Lorentzian broadening.')
#   parser.add_option('-e','--epsilon',dest='eps', action="store_true",default=False,
#   help='Print intensity in epsilon instead of a cross section.' )
#  --smooth (perform runnning average?)
   parser.add_option('','--notrans',dest='notrans', action="store_true",default=False,
   help='No transition dipole moments. Spectrum will be normalized to unity. Useful for ionizations.' )
   return parser.parse_args(sys.argv[1:])


# Some constants
EVtoJ = 1.602e-19
EPS = 8.854e-12
HPRIME = 6.626e-34/(2*math.pi)
C = 299792e3
DEB = 2.5*3.34e-30

class Spectrum(object):
   """Base class spectrum for reflection principle without broadening"""

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
      self.intensity = [ 0 for i in range(self.maxe/self.de)]
      for i in range(len(self.trans)):

         index = int( (self.maxe-self.exc[i]) / self.de )
         trans2 = self.trans[i][0]**2 + self.trans[i][1]**2 + self.trans[i][2]**2
         trans2 *= math.pi*self.exc[i]/(3*HPRIME*EPS*C*self.de)
         trans2 *= DEB * DEB * 1e4 / self.nsample
         self.intensity[index] += trans2

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
                  print("Error: Corrupted line "+str(i+1)+" in file "+infile)
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
      units = {}
      units['nm'] = 1239.8
      units['ev'] = 1.
      units['cm'] = 8065.7
      f = open(fileout, "w") 

      for i in range(len(self.intensity)):
         energy = (self.maxe-i*self.de)
         if unit == "nm":
            if units[unit]/energy < 1000:
              f.write('%f %e \n' % (units[unit]/energy, self.intensity[i]))
         else:
            f.write('%f %e \n' % (energy*units[unit], self.intensity[i]))

      f.close()


   def cross2eps(self):
      pass


class SpectrumBroad(Spectrum):
   """Derived class for spectra with empirial gaussian and/or lorentzian broadening"""

   def __init__(self, nsample, deltaE, sigma, tau):
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





options, args = read_cmd()
try:
   infile = args[0]
except:
   print("You did not specified input file. Type -h for help."); sys.exit(1)


"""
if options.tau != None or options.sigma != None:
   spectrum = SpectrumBroad(options.nsample, options.de, options.sigma, options.tau, options.notrans)
else:"""
spectrum = Spectrum(options.nsample, options.de, options.notrans)

spectrum.read_data(infile)

"""
if options.eps:
   yunits="cm^2*molecule^-1"
else:"""

yunits="cm^2*molecule^-1"
outfile="spectrum.nm."+str(options.nsample)+".dat"

print("Printing spectrum in units [ nm, "+yunits+"] to "+outfile )
spectrum.writeout("nm", outfile) 

outfile="spectrum.ev."+str(options.nsample)+".dat"
print("Printing spectrum in units [ eV, "+yunits+"] to "+outfile )
spectrum.writeout("ev", outfile) 

outfile="spectrum.cm."+str(options.nsample)+".dat"
print("Printing spectrum in units [ eV, "+yunits+"] to "+outfile )
spectrum.writeout("cm", outfile) 


