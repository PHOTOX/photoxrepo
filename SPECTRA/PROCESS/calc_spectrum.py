#!/usr/bin/env python
from __future__ import division
from optparse import OptionParser
import math
import sys

# TODO:
# 1. Gaussian and Lorentzian broadening
# (initial implementation done, but I am not sure about the intensities)

def read_cmd():
   """Function for reading command line options. Returns tuple options, args."""
   usage = "usage: %prog [options] input_file"
   parser = OptionParser(usage)
   parser.add_option('-n','--nsample',dest='nsample', type='int', default=1, help='Number of samples.')
   parser.add_option('-d','--de',dest='de', type='float', default=0.02, help='Bin step in eV. Default = 0.02 ')
   parser.add_option('-s','--sigma',dest='sigma', type='float', default=0.0, help='Parameter for Gaussian broadening.')
   parser.add_option('-t','--tau',dest='tau', type='float', default=0.0, help='Parameter for Lorentzian broadening.(not yet implemented)')
   parser.add_option('-e','--epsilon',dest='eps', action="store_true",default=False,
   help='Print intensity in epsilon instead of a cross section.' )
#  --smooth (perform runnning average?)
   parser.add_option('','--notrans',dest='notrans', action="store_true",default=False,
   help='No transition dipole moments. Spectrum will be normalized to unity. Useful for ionizations.' )
   return parser.parse_args(sys.argv[1:])


# Some constants
EVtoJ = 1.602e-19  # Joul
EPS = 8.854e-12
PI  = math.pi
HPRIME = 6.626e-34/(2*PI)
C = 299792e3
DEB = 2.5*3.34e-30
COEFF = PI * DEB**2 * 1e4 /( 3 * HPRIME * EPS * C )


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
      self.intensity = [ 0.0 for i in range(int(self.maxe/self.de))]
      for i in range(len(self.trans)):

         index = int (round( (self.maxe-self.exc[i]) / self.de ) )
         trans2 = self.trans[i][0]**2 + self.trans[i][1]**2 + self.trans[i][2]**2
         trans2 *= COEFF * self.exc[i] / self.de / self.nsample
         self.intensity[index] += trans2

   def normalize(self):
      for j in range(int( self.maxe/self.de )):
         self.intensity.append(0.0)

      for i in range(len(self.exc)):
         index = int( (self.maxe-self.exc[i]) / self.de )
         self.intensity[index] += 1.0 / self.nsample / self.de

   def cross2eps(self):
      for int in self.intensity:
         int *= 6.022140**20 / math.log(10)

   def read_data(self, infile):
      f = open(infile, "r") 
      i = 0
      with open(infile, "r") as f:
         for line in f:
            if i % 2 == 1 and self.notrans == False:
               temp = line.split()
               try:
                  # assigning transition dipole moments as a tuple
                  self.trans.append( ( float(temp[0]), float(temp[1]), float(temp[2]) ) )
               except:
                  print("Error: Corrupted line "+str(i+1)+" in file "+infile)
                  print("I expected 3 columns of transition dipole moments, got:")
                  print(line)
                  #raise
                  sys.exit(1)
            else:
               try:
                  self.exc.append(float( line ))
               except:
                  print("Error when reading file "+infile+" on line: "+str(i+1))
                  print("I expected excitation energy, but got:"+line)
#                  raise
                  sys.exit(1)

            i += 1

#      assert(len(self.exc)==len(self.trans))
      if len(self.exc) != len(self.trans):
         print("Error: Number of excitations does not match number of transition dipole moments.")
         sys.exit(1)

      self.maxe = max(self.exc)+3.0
      if self.notrans == True:
         self.normalize()
      else:
         self.trans2intensity()

      f.close()

   def writeout(self, xunit, fileout):
      units = {}
      units['nm'] = 1239.8
      units['ev'] = 1.
      units['cm'] = 8065.7
      f = open(fileout, "w") 

      for i in range(len(self.intensity)-1, -1, -1):
         energy = (self.maxe-i*self.de)
         if xunit == "nm":
            if units[xunit]/energy < 1000:
              f.write('%f %e \n' % (units[xunit]/energy, self.intensity[i]))
         else:
            f.write('%f %e \n' % (energy*units[xunit], self.intensity[i]))

      f.close()



class SpectrumBroad(Spectrum):
   """Derived class for spectra with empirial gaussian and/or lorentzian broadening"""

   def __init__(self, nsample, deltaE, sigma, tau, notrans):
      self.trans = []
      self.exc = []
      self.int_tau = []
      self.int_sigma = []
      self.sigma = sigma
      self.tau = tau
      self.nsample = nsample
      self.notrans = False
      self.de = deltaE # in eV
      if notrans == True:
         self.notrans = True

   def trans2intensity(self):
      self.int_sigma = [ 0.0 for i in range(len(self.exc))]
      self.int_tau = [ 0.0 for i in range(len(self.exc))]
      for i in range(len(self.exc)):

         trans2 = self.trans[i][0]**2 + self.trans[i][1]**2 + self.trans[i][2]**2
         trans2 *= COEFF * self.exc[i] / self.nsample
         if self.sigma > 0:
            self.int_sigma[i] = trans2  / math.sqrt(2*PI) / self.sigma
         if self.tau > 0:
            self.int_tau[i] += trans2 * self.tau / 2 / PI
         if self.sigma > 0 and self.tau > 0.0:
            self.int_sigma[i] /= 2
            self.int_tau[i] /= 2

   def normalize(self):
      if self.sigma > 0:
         self.int_sigma = [ 1.0 / self.sigma / math.sqrt(2*PI) / self.nsample for i in range(len(self.exc))]
      if self.tau > 0:
         self.int_tau = [ self.tau / (2*PI) / self.nsample for i in range(len(self.exc))]
      if self.sigma > 0.0 and self.tau > 0.0:
         for i in range(len(self.int_tau)):
            self.int_sigma[i] /= 2.0
            self.int_tau[i] /= 2.0

   def writeout(self, xunit, fileout):
      units = {}
      units['nm'] = 1239.8
      units['ev'] = 1.
      units['cm'] = 8065.7
      f = open(fileout, "w") 

      if xunit == "nm" or xunit == "cm":
         print("The nm and cm units are not yet supported with broadening.")

      for i in range(int( self.maxe/self.de )-1, -1, -1):
         total = 0.0
         energy = (self.maxe-i*self.de)
         for j in range(len(self.exc)):
            if self.sigma > 0.0:
               total += self.int_sigma[j]*math.exp(-( (energy-self.exc[j])**2 )/2/self.sigma**2 )
            if self.tau > 0.0:
               total += self.int_tau[j] / ( (energy-self.exc[j])**2 +(self.tau**2)/4 )

         f.write('%f %e \n' % (energy*units[xunit], total ))

      f.close()





options, args = read_cmd()
try:
   infile = args[0]
except:
   print("You did not specified input file. Type -h for help."); sys.exit(1)



if options.tau > 0.0 or options.sigma > 0.0:
   spectrum = SpectrumBroad(options.nsample, options.de, options.sigma, options.tau, options.notrans)
else:
   spectrum = Spectrum(options.nsample, options.de, options.notrans)

spectrum.read_data(infile)


if options.eps:
   if options.notrans:
      print("Error in input: you did not provide intensities,\n\
but yet you still want to convert to molar absorption coefficient.\n\
Make up your mind and try again.")
      sys.exit(1)
   print("Converting intensity to epsilon.")
   spectrum.cross2eps()
   yunits="dm^3*mol^-1*cm"
else:
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


