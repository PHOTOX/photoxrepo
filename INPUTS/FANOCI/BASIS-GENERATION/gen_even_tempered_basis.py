#!/usr/bin/env python3

import argparse, sys, math

def read_cmd():
   """Reads command line params"""
   desc = "Generate even-tempered basis set for TeraChem"
   parser = argparse.ArgumentParser(description=desc)
   parser.add_argument("-n", dest="nbasis", type=int, required=True, help="Number of basis funcs")
   parser.add_argument("-f", "--amax", dest="amax", type=float, default=100.0, help="Maximum exponent")
   parser.add_argument("-i", "--amin", dest="amin", type=float, help="Minimum exponent (NOT WORKING YET)")
   return parser.parse_args()


def get_even_tempered_exponents(amin, amax, nbasis):
   """Get alpha exponents for even tempered basis
   According to Ref. 64 in  """
   # TODO: Make beta dependent on amin
   beta = 0.01
   alphas = []
   alphas.append(amax)
   for i in range(1, nbasis):
      a = amax * beta**(i / (nbasis-1))
      alphas.append(a)
   return alphas

def print_cgto(alphas, coeffs, l, f):
   """Print contracted Gaussian of given momentum"""
   if len(alphas) != len(coeffs):
      print("ERROR: incompatible inputs in \"print_cgto\"")
      sys.exit(1)

   f.write("%s %d\n" % (l, len(alphas)))
   for i in range(len(alphas)):
      f.write("   %15.7f %15.7f\n" % (alphas[i], coeffs[i]))

def print_basis(alphas):
   """Prints GTOs in a basis file format for TC"""
   # For now, harcoded to print s,p,d functions for each alpha
   # Completely decontracted basis
   fname = "basis_evtemp_%d" % (len(alphas))
   with open(fname, "w") as f:
      for a in alphas:
         for l in "SPD":
            print_cgto([a], [1.0], l, f)


if __name__ == '__main__':
   opts = read_cmd()

   exponents = get_even_tempered_exponents(opts.amin, opts.amax, opts.nbasis)
   print_basis(exponents)

