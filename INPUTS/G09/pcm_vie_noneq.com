%mem=1600MB
%chk=test.chk
%nproc=1
#BLYP/6-31g* GFINPUT IOP(6/7=3) scrf(pcm,read,solvent=water) nosymm

cytosin, VIE, PCM

0 1
 C    13.525254    15.312722    14.243518
 N    14.063254    16.357825    14.919766
 C    13.323953    17.504282    15.316833
 N    11.995191    17.518888    14.976737
 C    11.467223    16.504814    14.317280
 C    12.209283    15.326154    13.907080
 O    13.908593    18.380092    15.922072
 N    10.156415    16.569428    14.001326
 O     9.245378    14.033703    12.692910
 H     9.639212    17.378141    14.311201
 H     9.687947    15.801442    13.535792
 H    11.729720    14.517083    13.366706
 H    14.196190    14.492238    13.999536
 H    15.038740    16.373746    15.184505
 H     8.796442    13.345320    13.196683
 H     8.959035    13.918172    11.779766

icomp=0 noneq=write radii=uff alpha=1.1
! radii and alpha params have default values here

--link1--
%mem=1600MB
%nProc=1
%chk=test.chk
#p BLYP/6-31g* guess=(read) geom=check nosymm scrf(pcm,read,solvent=water) test  gfinput iop(6/7=3)

cytosin, VIE, PCM

1,2

icomp=0 noneq=read radii=uff alpha=1.1
