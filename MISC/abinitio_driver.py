from subprocess import call
from sys import exit
import shutil
import os

TERA_VERSION = "dev"
QCHEM_VERSION = "4.3"
CHECK_SCF = True


# This is only for debug purposes
DRY_RUN = False

"""GS = Ground State
   IS = Ionized State
"""

__counter__ = 0
AUtoEV = 27.2114
__LAST_SCRDIR_RESTRICTED__  = ""
__LAST_SCRDIR_UNRESTRICTED__ = ""


class Abinitio_driver():
   """Base class for drivers"""

   BASEFILE_GS = "optomega_gs.inp"
   BASEFILE_IS = "optomega_is.inp"
   def zero_counter():
      global __counter__
      global __LAST_SCRDIR_RESTRICTED__
      global __LAST_SCRDIR_UNRESTRICTED__
      __LAST_SCRDIR_RESTRICTED__  = ""
      __LAST_SCRDIR_UNRESTRICTED__ = ""
      __counter__ = 0

   def prepare_input_wrapper(self, basefile, inpfile):
      """This function hides the logic of where to get the initial WF guess.
      For restricted wf, we take only restricted guess.
      For unrestricted, we try to take unrestricted, or restricted, if the former is not available."""
      global __LAST_SCRDIR_RESTRICTED__
      global __LAST_SCRDIR_UNRESTRICTED__
      if self.is_restricted(basefile):
          if __LAST_SCRDIR_RESTRICTED__:
             __LAST_SCRDIR_RESTRICTED__ = self.prepare_input(basefile, inpfile, __LAST_SCRDIR_RESTRICTED__)
          else:
             __LAST_SCRDIR_RESTRICTED__ = self.prepare_input(basefile, inpfile)
      else:
          if __LAST_SCRDIR_UNRESTRICTED__:
             __LAST_SCRDIR_UNRESTRICTED__ = self.prepare_input(basefile, inpfile, __LAST_SCRDIR_UNRESTRICTED__)
          elif __LAST_SCRDIR_RESTRICTED__:
             __LAST_SCRDIR_UNRESTRICTED__ = self.prepare_input(basefile, inpfile, __LAST_SCRDIR_RESTRICTED__)
          else:
             __LAST_SCRDIR_UNRESTRICTED__ = self.prepare_input(basefile, inpfile)

   def compute_ip(self, omega):
      """This driver function should be the same for all drivers.
      Expecting omega in atomic units."""
      global __counter__
      global AUtoEV
      global __LAST_SCRDIR_RESTRICTED__
      global __LAST_SCRDIR_UNRESTRICTED__
      self.omega = omega

      # First, calculate ground state
      inpfile = "gs."+str(__counter__)+".inp"
      self.prepare_input_wrapper(self.BASEFILE_GS, inpfile)
      outfile, outfile2 = self.run_energy(inpfile)
      en_scf_gs = self.get_energy_scf(outfile)
      en_homo   = self.get_energy_homo(outfile2)

      # Now get ionized state
      inpfile = "is."+str(__counter__)+".inp"
      self.prepare_input_wrapper(self.BASEFILE_IS, inpfile)
      outfile, outfile2 = self.run_energy(inpfile)
      en_scf_is = self.get_energy_scf(outfile)

      ip_koop = -en_homo
      ip_dscf = en_scf_is - en_scf_gs
      err   = ip_dscf - ip_koop

      with open("omegas.dat", "a") as f:
          if __counter__ == 0:
              f.write("# omega   dSCF    Koop    deltaIP\n")
          string = str(round(omega,3))+"  "
          string += str(round(ip_dscf*AUtoEV,3))+"  "
          string += str(round(ip_koop*AUtoEV,3))+"  "
          string += str(round(err*AUtoEV,3))+"\n"
          f.write(string)

      __counter__ += 1

      return ip_dscf, ip_koop

   # The following methods must be defined in derived classes 
   def prepare_input(self, basefile, inpfile):
      pass

   def run_energy(self, inpfile):
      pass

   def get_energy_scf(self, outfile):
      pass

   def get_energy_homo(self, outfile):
      pass

   def is_restricted(self, inpfile):
      pass



class Abinitio_driver_terachem(Abinitio_driver):

   def is_restricted(self, inpfile):
        """Determine whether we have unrestricted or restricted method"""
        with open(inpfile, "r") as bf:
            for line in bf:
                l = line.split()
                if l[0] == "method":
                    if l[1][0] == "u":
                        return False
                    else:
                        return True

   def prepare_input(self, basefile, inpfile, wfguessdir = ""):
      guess = ""
      if len(wfguessdir) and not DRY_RUN:
          guess = "guess  "
          if self.is_restricted(basefile):
              guess += wfguessdir + "/c0\n"
          else: 
              # UNRESTRICTED case
              # First, take care if we get guess from restricted calculation
              # In that case, we need to copy c0 to ca and cb
              if not os.path.isfile(wfguessdir+"/ca0"):
                  infile = wfguessdir+"/c0"
                  outfile = wfguessdir+"/ca0"
                  shutil.copy(infile, outfile)
                  outfile = wfguessdir+"/cb0"
                  shutil.copy(infile, outfile)
              guess += wfguessdir + "/ca0 "
              guess += wfguessdir + "/cb0\n"

      self.scrdir = "scr-"+inpfile.lower().split(".inp")[0]
      self.jobname = "jobname"
      if DRY_RUN:
          return self.scrdir
      with open(inpfile, "w") as of:
         of.write("scrdir  " + self.scrdir+"\n")
         of.write("jobname  " + self.jobname+"\n")
         of.write("rc_w  "+str(self.omega)+"\n")
         of.write(guess)
         with open(basefile,"r") as bf:
            of.write(bf.read())

      return self.scrdir


   def run_energy(self, inpfile):
#     The following does not work
#     we need terachem executable defined beforehand
#     call(["SetEnvironment.sh TERACHEM " + TERA_VERSION + "&& env"])
      outfile = inpfile+".out"
      if not DRY_RUN:
         call(["TERA", inpfile, TERA_VERSION])
      # One could do parallel execution using Popen
      # But this is a bad idea, since unrestricted calculations
      # take 2 times longer

      # return the names of output files
      # first should contain SCF energy
      # second should contain HOMO energy
      return outfile, self.scrdir+"/"+self.jobname+".molden"

   def get_energy_scf(self, outfile):
      """Get SCF energy from standard TeraChem output file"""
      with open(outfile, "r") as f:
         for line in f:
            l = line.split()
            if not len(l):
               continue
            if l[0] == "SCF" and l[1] == "did":
               print("ERROR: SCF did not converge! See file "+outfile)
               if CHECK_SCF:
                  exit(1)
            if l[0] == "FINAL":
               en_scf = float(l[2])
               return en_scf
      print("ERROR: Could not find SCF energy in file "+outfile)
      exit(1)

   def get_energy_homo(self, outfile):
      """Get HOMO energy from Molden file"""
      with open(outfile, "r") as f:
         for line in f:
            l = line.split()
            if len(l) < 2:
               continue
            if l[0] == "Ene=":
               en_temp = l[1]
            if l[0] == "Occup=":
               occ = l[1]
               if occ == "0.0":
                  return float(energy)
               else:
                  energy = en_temp

      print("ERROR: Could not find HOMO energy in file "+outfile)
      exit(1)



class Abinitio_driver_qchem(Abinitio_driver):

   def __init__(self):
      self.SCRDIR_R = "scr-restricted"
      self.SCRDIR_U = "scr-unrestricted"

   def is_restricted(self, inpfile):
       """ This one might be more tricky."""
       read_spin = False
       rest = True
       with open(inpfile,"r") as bf:
          for line in bf:
             l = line.split()
             if not len(l):
                continue
             if read_spin:
                if l[1] > 1:
                   # for non-singlet multiplicity, unrestricted is default
                   rest = False
                read_spin = False
             if l[0].lower() == "$molecule":
                read_spin = True
             if l[0].upper() == "UNRESTRICTED":
                if l[1].upper() == "TRUE":
                   return False
                else:
                   return True

       return rest


   def prepare_input(self, basefile, inpfile, wfguess=False):
       global __counter__
       if DRY_RUN:
           return self.SCRDIR_R
       
       with open(basefile,"r") as bf:
           with open(inpfile,"w") as of:
               for line in bf:
                   l = line.split()
                   if not len(l):
                      continue
                   if l[0].upper() == "OMEGA":
                       of.write("OMEGA "+str(int(self.omega*1000))+"\n")
                   elif l[0].upper() == "$REM" and wfguess:
                       of.write(line)
                       of.write("scf_guess  read\n")
                   else:
                       of.write(line)
       if self.is_restricted(basefile):
          return self.SCRDIR_R
       else:
          if os.path.isdir(self.SCRDIR_U):
             return self.SCRDIR_U
          else:
             return self.SCRDIR_R


   def get_energy_scf(self, outfile):
      """Get SCF energy from standard QCHEM output file"""
      with open(outfile, "r") as f:
         for line in f:
            l = line.split()
            if len(l) < 9:
               continue
            #TODO need to check SCF convergence somehow
#            if line[0] == "SCF" and line[1] == "did":
#               print("ERROR: SCF did not converge!"+outfile)
#               exit(1)
            if l[0] == "SCF" and l[1] == "energy":
               en_scf = float(l[8])
               return en_scf
      print("ERROR: Could not find SCF energy in file "+outfile)
      exit(1)

   def get_energy_homo(self, outfile):
      """Get HOMO energy from standard QCHEM output file"""
      with open(outfile, "r") as f:
         read = False
         line_last = []
         MO_energies = []
         for line in f:
            l = line.split()
            if not len(l):
               continue
            if l[0] == "--" and l[1] == "Occupied":
                read = True
            elif l[0] == "--" and l[1] == "Virtual":
                # take last occupied alpha orbital
                en_homo = float(MO_energies[-1])
                return en_homo
            elif read:
                MO_energies = line_last
                line_last = l
      print("ERROR: Could not find HOMO energy in file "+outfile)
      exit(1)


   def run_energy(self, inpfile):
      #user = os.environ["USER"]
      #os.environ["QCLOCALSCR"] = "/home/"+user
      #os.environ["QCSCRATCH"] = self.scrdir
      outfile = inpfile+".out"
      if self.is_restricted(inpfile):
         scrdir = self.SCRDIR_R
      else:
         if os.path.isdir(self.SCRDIR_U):
            scrdir = self.SCRDIR_U
         else:
            scrdir = self.SCRDIR_R
      if not DRY_RUN:
         call(["QCHEM", inpfile, QCHEM_VERSION, "openmp", scrdir])
      # return the names of output files
      # first should contain SCF energy
      # second should contain HOMO energy
      return outfile, outfile


