#!/usr/bin/env python
from __future__ import division
# NOTE: optparse deprecated in python3, but still supported
from optparse import OptionParser
import math
import sys
import numpy
import random
import time
import os

def read_cmd():
   """Function for reading command line options. Returns tuple options, args."""
   usage = "usage: %prog [options] input_file"
   parser = OptionParser(usage)
   parser.add_option('-n','--nsample',dest='nsample', type='int', default=1, help='Number of samples.')
   parser.add_option('-S','--subset',dest='subset', type='int', default=0, help='Number of representative molecules.')
   parser.add_option('-c','--cycles',dest='cycles', type='int', default=100, help='Number of cycles for geometries reduction.')
   parser.add_option('-j','--ncores',dest='ncores', type='int', default=1, help='Number of cores for parallel execution of geometries reduction.')
   parser.add_option('-J','--jobspercore',dest='jobs', type='int', default=1, help='Number of reduction jobs per one core.')
   parser.add_option('-d','--de',dest='de', type='float', default=0.02, help='Bin step in eV. Default = 0.02 ')
   parser.add_option('-s','--sigma',dest='sigma', type='float', help='Parameter for Gaussian broadening.')
   parser.add_option('-t','--tau',dest='tau', type='float', default=0.0, help='Parameter for Lorentzian broadening.')
#  --smooth (perform runnning average?)
   parser.add_option('','--notrans',dest='notrans', action="store_true",default=False,
   help='No transition dipole moments. Spectrum will be normalized to unity. Useful for ionizations.' )
   return parser.parse_args(sys.argv[1:])


# Some constants
EVtoJ = 1.602177e-19  # Joul
EPS = 8.854188e-12
PI = math.pi
HPRIME = 6.626070e-34/(2*PI)
C = 299792458
AUtoCm = 8.478354e-30
COEFF = PI * AUtoCm**2 * 1e4 /(3 * HPRIME * EPS * C)

test = 1 # 1 for Komogorov-Smirnov test, 2 for Kuiper test, 3 for differences sum, 4 for integral differences sum

# not needed anymore with numpy package
#def weightedMean(values, weights):
#   totalWeight = sum(weights)
#   totalValue = 0
#   for i in range(len(values)):
#      totalValue += values[i]*weights[i]
#   weightedMean = totalValue/totalWeight
#   return weightedMean

def weightedDev(values,weights):
   mean = numpy.average(values, weights=weights)
   variance = numpy.average((values-mean)**2, weights=weights)
   return math.sqrt(variance)

class Spectrum(object):
   """Base class spectrum for reflection principle without broadening"""

   def __init__(self, nsample, deltaE, notrans, subset, cycles, ncores, jobs):
      self.trans = []
      self.intensity = []
      self.exc = []
      self.energies = []
      self.samples = []
      self.subsamples = []
      self.restsamples = []
      self.subsamplesact = []
      self.restsamplesact = []
      self.maxe = 0.0
      self.nsample = nsample
      self.notrans = False
      self.de = deltaE # in eV
      self.subset = subset
      self.cycles = cycles
      self.ncores = ncores
      self.jobs = jobs
      self.pid = os.getpid()
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
#     self.intensity = [ 0.0 for i in range(int( self.maxe/self.de )) ]
#     self.intensity = [0] * int( self.maxe/self.de )
      for j in range(int( self.maxe/self.de )):
         self.intensity.append(0.0)

      for i in range(len(self.exc)):
         index = int( (self.maxe-self.exc[i]) / self.de )
         self.intensity[index] += 1.0 / self.nsample / self.de

   def cross2eps(self): 
      """Conversion to molar exctinction coefficient"""
      for i in range(len(self.intensity)):
         self.intensity[i] *= 6.022140e20 / math.log(10)

   def KStest(self):
      forig = 0.0
      fact = 0.0
      d = 0.0
      for i in range(len(self.origintensity)):
         forig += self.origintensity[i]
         fact += self.intensity[i]
         dact = abs(forig-fact) # KS test
         if dact > d:
            d = dact
      return d

   def kuiper(self):
      forig = 0.0
      fact = 0.0
      dminus = 0.0
      dplus = 0.0
      for i in range(len(self.origintensity)):
         forig += self.origintensity[i]
         fact += self.intensity[i]
         dact = forig-fact
         dminusact = forig-fact
         dplusact = -dminusact
         if dminusact > dminus:
            dminus = dminusact
         if dplusact > dplus:
            dplus = dplusact
      d = dplus+dminus
      return d

   def diffsum(self):
      d = 0.0
      for i in range(len(self.origintensity)):
         d += abs(self.origintensity[i] - self.intensity[i])
      return d

   def intdiffsum(self):
      forig = 0.0
      fact = 0.0
      d = 0.0
      for i in range(len(self.origintensity)):
         forig += self.origintensity[i]
         fact += self.intensity[i]
         d += abs(forig-fact)
      return d

   def calc_diff(self):
      if test == 1:
         d = self.KStest()
      elif test == 2:
         d = self.kuiper()
      elif test == 3:
         d = self.diffsum()
      else:
         d = self.intdiffsum()
      return d

   def select_subset(self):
       self.subsamples = random.sample(range(1, len(self.exc_orig), 1),self.subset)
       self.restsamples = list(set(range(1, len(self.exc_orig), 1)) - set(self.subsamples))
  
   def select_subsetact(self):
       self.subsamplesact = random.sample(range(1, len(self.exc_orig), 1),self.subset)
       self.restsamplesact = list(set(range(1, len(self.exc_orig), 1)) - set(self.subsamplesact))
 
   def swap_samples(self):
       random_subindex = random.randrange(len(self.subsamplesact))
       random_restindex = random.randrange(len(self.restsamplesact))
       self.subsamplesact[random_subindex], self.restsamplesact[random_restindex] = self.restsamplesact[random_restindex], self.subsamplesact[random_subindex]

   def SA(self,test=0):
      pi = 0.70
      pf = 0.30
      if test == 1:
         it = 1
         d = self.calc_diff()
         diffmax = 0
         diffmin = d
      else:
         self.select_subset()
         self.exc = list( self.exc_orig[i] for i in self.subsamples )
         self.trans = list( self.trans_orig[i] for i in self.subsamples )
         if self.notrans == True:
            self.normalize()
         else:
            self.trans2intensity()
         self.finish_spectrum()
         d = self.calc_diff()
         if self.subset>=8:
            itmax = self.subset/4
         elif self.subset>=4:
            itmax = self.subset/2
         elif self.subset>=2:
            itmax = self.subset
         else:
            itmax = 2*self.subset
         itmin = itmax/2
         itc = math.exp((math.log(itmax)-math.log(itmin))/self.cycles)
         it = itmin
         start = time.time()
         ti,tf = self.SA(1)
         end = time.time()
         m,s = divmod(int(round((itmax+itmin)*(end-start)/2)), 60)
         h,m = divmod(m, 60)
         tc = math.exp((math.log(tf)-math.log(ti))/self.cycles)
         temp = ti
         toprint = str(self.pid)+":\tInitial temperature = "+str(ti)+", Final temperature = "+str(tf)+", Temperature coefficient = "+str(tc)
         toprint += "\n\tMarkov Chain Length coefficient = "+str(itc)+", Initial D-min = "+str(d)
         toprint += "\n\tEstimated run time: "+str(h)+" hours "+str(m)+" minutes "+str(s)+" seconds"
         print(toprint)
         sys.stdout.flush()
      dact = d
      for j in range(self.cycles):
         for k in range(int(round(it))): 
            self.subsamplesact = self.subsamples[:]
            self.restsamplesact = self.restsamples[:]
            self.swap_samples()
            self.exc = list( self.exc_orig[i] for i in self.subsamplesact )
            self.trans = list( self.trans_orig[i] for i in self.subsamplesact )
            if self.notrans == True:
               self.normalize()
            else:
               self.trans2intensity()
            self.finish_spectrum()
            dact = self.calc_diff()
            if test == 1:
               prob = 1
               if dact > d:
                  if (dact-d) > diffmax:
                     diffmax = dact-d
                  elif (dact-d) < diffmin:
                     diffmin = dact-d
            else:
               if dact < d:
                  prob = 1.0
               else:
                  prob = math.exp((d - dact)/ temp)
#            print("d - dact"+str(d - dact)+"temp"+str(temp)+"prob"+str(prob))
            if prob >= random.random():
               self.subsamples = self.subsamplesact
               self.restsamples = self.restsamplesact
               d = dact
#               print("Sample"+str(j)+"Round"+str(k)+": D-min ="+str(d)+"Temperature : T = "+str(temp))
         if test == 0:
            temp *= tc
            it *= itc
      if test == 1:
         return -diffmax/math.log(pi), -diffmin/math.log(pf)
      else:
         return d

   def random_search(self):
      d = self.calc_diff()
      print("Initial sample : D-min = "+str(d))
      dact = d
      for i in range(self.cycles):
         self.select_subsetact()
         self.exc = list( self.exc_orig[i] for i in self.subsamplesact )
         self.trans = list( self.trans_orig[i] for i in self.subsamplesact )
         if self.notrans == True:
            self.normalize()
         else:
            self.trans2intensity()
         self.finish_spectrum()
         dact = self.calc_diff()
         if dact <= d:
            self.subsamples = self.subsamplesact
            self.restsamples = self.restsamplesact
            d = dact
            print("Sample"+str(i)+": D-min ="+str(d))

   def reduce_geoms(self,infile):
      if self.notrans == True:
         self.normalize()
      else:
         self.trans2intensity()
      self.finish_spectrum()
      toprint = "Original spectrum sigma: "+str(self.sigma)
      toprint += "\nPrinting original spectra:"
      self.writeoutall(infile,toprint)
      sys.stdout.flush()
      self.origintensity = self.intensity[:]
      self.exc_orig = self.exc
      self.trans_orig = self.trans
      self.nsample = self.subset

      jobs = []
      for i in range(self.ncores):
         pid = os.fork()
         if pid == 0:
            for j in range(self.jobs):
               self.pid = str(os.getpid())+"_"+str(j);
               random.seed()
               random.jumpahead(os.getpid())
               d = self.SA()
               toprint = str(self.pid)+":\tFinal D-min = "+str(d)
               toprint += "\n\tReduced spectrum sigma: "+str(self.sigma)
               toprint += "\n\tPrinting reduced spectra:"
               self.writeoutall(infile,toprint)
               self.writegeoms(infile)
               sys.stdout.flush()
            os._exit(0)
         jobs.append(pid)
      for job in jobs:
         os.waitpid(job,0)

   def read_data(self, infile):
      i = 0
      with open(infile, "r") as f:
         for line in f:
            #if (self.notrans == True and self.subset == 0 and i >= self.nsample) or (self.notrans == True and self.subset > 0 and i >= 2*self.nsample) or (self.notrans == False and self.subset == 0 and i >= 2*self.nsample) or (self.notrans == False and self.subset > 0 and i >= 3*self.nsample):
            #   break
            if (i % 3 == 1 and self.subset > 0 and self.notrans == False) or (i % 2 == 1 and self.subset == 0 and self.notrans == False):
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
            elif (i % 3 == 2 and self.subset > 0 and self.notrans == False) or (i % 2 == 1 and self.subset > 0 and self.notrans ==True):
               try:
                  self.samples.append( line )
               except:
                  print("Error when reading file "+infile+" on line: "+str(i+1))
                  print("I expected name of the file, but got:"+line)
#                  raise
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
      if len(self.exc) != len(self.trans) and not self.notrans:
         print("Error: Number of excitations does not match number of transition dipole moments.")
         sys.exit(1)
      if len(self.exc) != len(self.samples) and self.subset > 0:
         print("Error: Number of excitations does not match number of samples.")
         sys.exit(1)

      self.maxe = max(self.exc)+0.5
      self.minE = min(self.exc)-0.5
      f.close()
   
   def finish_spectrum(self):
      self.energies = [ 0.0 for i in range(len(self.intensity)-1, -1, -1)]
      for i in range(len(self.intensity)-1, -1, -1):
         self.energies[i] = (self.maxe-i*self.de)

   def writeout(self, xunit, fileout):
      units = {}
      units['nm'] = 1239.8
      units['ev'] = 1.
      units['cm'] = 8065.7
      f = open(fileout, "w") 

      for i in range(len(self.intensity)-1, -1, -1):
         if self.energies[i] < self.minE:
            continue
         if xunit == "nm":
            if units[xunit]/self.energies[i] < 1000:
              f.write('%f %e \n' % (units[xunit]/self.energies[i], self.intensity[i]))
         else:
            f.write('%f %e \n' % (self.energies[i]*units[xunit], self.intensity[i]))

      f.close()
   
   def writeoutall(self,infile,message=""):
      name = infile.split(".")[0] # take the first part of the input file, before first dot

      yunits="cm^2*molecule^-1"
      xunits = [ "ev", "nm", "cm"]
      toprint = message
      for un in xunits:
         outfile="absspec."+name+".n"+str(self.nsample)+"."+str(self.pid)+'.'+un+".cross.dat"
         toprint += "\n\tPrinting spectrum in units [ "+un+", "+yunits+"] to "+outfile
         self.writeout(un, outfile)

      # Now convert to molar exctiction coefficient
      helpints = self.intensity[:]
      self.cross2eps()
      yunits="dm^3*mol^-1*cm^-1"
      for un in xunits:
         outfile="absspec."+name+".n"+str(self.nsample)+'.'+str(self.pid)+"."+un+".molar.dat"
         toprint += "\n\tPrinting spectrum in units [ "+un+", "+yunits+"] to "+outfile
         self.writeout(un, outfile)
      print(toprint)
      self.intensity = helpints

   def writegeoms(self,infile):
      name = infile.split(".")[0]
      outfile = name+".n"+str(self.nsample)+"."+str(self.pid)+".geoms"
      print(str(self.pid)+":\tPrinting geometries of reduced spectrum to "+outfile)
      f = open(outfile, "w")
      for i in self.subsamples:
         f.write('%s' % (self.samples[i]))
      f.close()


class SpectrumBroad(Spectrum):
   """Derived class for spectra with empirical gaussian and/or lorentzian broadening"""

   def __init__(self, nsample, deltaE, sigma, tau, notrans, subset, cycles, ncores, jobs):
      self.trans = []
      self.intensity = []
      self.exc = []
      self.energies = []
      self.samples = []
      self.subsamples = []
      self.restsamples = []
      self.subsamplesact = []
      self.restsamplesact = []
      self.int_tau = []
      self.int_sigma = []
      self.acs = []
      self.sigma = sigma
      self.tau = tau
      self.nsample = nsample
      self.notrans = False
      self.de = deltaE # in eV
      self.subset = subset
      self.cycles = cycles
      self.ncores = ncores
      self.jobs = jobs
      self.pid = os.getpid()
      if notrans == True:
         self.notrans = True

   def setSigma(self):
      if self.notrans == True:
         dev = numpy.std(self.exc)
      else:
         dev = weightedDev(self.exc,self.acs)
      self.sigma = (4. * dev ** 5. / 3. / self.nsample) ** (1./5.)

   def trans2intensity(self):
      self.int_sigma = [ 0.0 for i in range(len(self.exc))]
      self.int_tau = [ 0.0 for i in range(len(self.exc))]
      self.acs = [ 0.0 for i in range(len(self.exc))]
      for i in range(len(self.exc)):
         trans2 = self.trans[i][0]**2 + self.trans[i][1]**2 + self.trans[i][2]**2
         self.acs[i] = trans2 * COEFF * self.exc[i] / self.nsample
      if(self.sigma == 0) or (self.subset > 0):
         self.setSigma()
      for i in range(len(self.exc)):
         if self.sigma > 0:
            self.int_sigma[i] = self.acs[i]  / math.sqrt(2*PI) / self.sigma
         if self.tau > 0:
            self.int_tau[i] += self.acs[i] * self.tau / 2 / PI
         if self.sigma > 0 and self.tau > 0.0:
            self.int_sigma[i] /= 2
            self.int_tau[i] /= 2

   def normalize(self):
      if(self.sigma == 0):
         self.setSigma()
      if self.sigma > 0:
         self.int_sigma = [ 1.0 / self.sigma / math.sqrt(2*PI) / self.nsample for i in range(len(self.exc))]
      if self.tau > 0:
         self.int_tau = [ self.tau / (2*PI) / self.nsample for i in range(len(self.exc))]
      if self.sigma > 0.0 and self.tau > 0.0:
         for i in range(len(self.int_tau)):
            self.int_sigma[i] /= 2.0
            self.int_tau[i] /= 2.0
   
   def finish_spectrum(self):
      self.energies = [ 0.0 for i in range(int( self.maxe/self.de )-1, -1, -1)]
      self.intensity = [ 0.0 for i in range(int( self.maxe/self.de )-1, -1, -1)]
      for i in range(int( self.maxe/self.de )-1, -1, -1):
         self.energies[i] = (self.maxe-i*self.de)
         for j in range(len(self.exc)):
            if self.sigma > 0.0:
               self.intensity[i] += self.int_sigma[j]*math.exp(-( (self.energies[i]-self.exc[j])**2 )/2/self.sigma**2 )
            if self.tau > 0.0:
               self.intensity[i] += self.int_tau[j] / ( (self.energies[i]-self.exc[j])**2 +(self.tau**2)/4 )

   def writeout(self, xunit, fileout):
      units = {}
      units['nm'] = 1239.8
      units['ev'] = 1.
      units['cm'] = 8065.7
      f = open(fileout, "w") 

      for i in range(int( self.maxe/self.de )-1, -1, -1):
         if self.energies[i] < self.minE:
            continue
         if xunit == "nm":
            if units[xunit]/self.energies[i] < 1000:
              f.write('%f %e \n' % (units[xunit]/self.energies[i], self.intensity[i] ))
         else:
            f.write('%f %e \n' % (self.energies[i]*units[xunit], self.intensity[i] ))

      f.close()


options, args = read_cmd()
try:
   infile = args[0]
except:
   print("You did not specified input file. Type -h for help."); sys.exit(1)
if options.tau > 0.0 or options.sigma is not None:
   spectrum = SpectrumBroad(options.nsample, options.de, options.sigma, options.tau, options.notrans, options.subset, options.cycles, options.ncores, options.jobs)
else:
   spectrum = Spectrum(options.nsample, options.de, options.notrans,options.subset, options.cycles, options.ncores, options.jobs)

spectrum.read_data(infile)
if spectrum.subset > 0:
   spectrum.reduce_geoms(infile)
else:
   if spectrum.notrans == True:
      spectrum.normalize()
   else:
      spectrum.trans2intensity()
   spectrum.finish_spectrum()
   spectrum.writeoutall(infile)

