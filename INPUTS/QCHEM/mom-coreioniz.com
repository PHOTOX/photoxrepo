Example input calculating 1s core ionized state of NH4+

$molecule
1 1
   N        -1.317523    0.000182   -0.000050
   H        -1.660602    0.961786   -0.018108
   H        -1.656073   -0.466260    0.842864
   H        -0.296335    0.003263   -0.000335
   H        -1.656504   -0.497876   -0.824454
$end
$rem
BASIS General
exchange HF
MAX_SCF_CYCLES 100
correlation MP2
$end

$basis
H 0
cc-pVTZ
****
O 0
cc-pCVTZ
****
N 0
cc-pCVTZ
****
$end

@@@
$molecule
2 2
   N        -1.317523    0.000182   -0.000050
   H        -1.660602    0.961786   -0.018108
   H        -1.656073   -0.466260    0.842864
   H        -0.296335    0.003263   -0.000335
   H        -1.656504   -0.497876   -0.824454
$end
$rem
BASIS General
exchange HF
correlation MP2   ! any single reference ground state method can be put here
scf_guess read
mom_start 1
unrestricted true
MAX_SCF_CYCLES 100
$end
THRESH 9
SCF_CONVERGENCE 6


$basis
H 0
cc-pVTZ
****
O 0
cc-pCVTZ
****
N 0
cc-pCVTZ
****
$end

core 1s electron ionized

$occupied
1 2 3 4 5 
  2 3 4 5 
$end


