%Mem=500Mb
%NprocShared=1
#B3LYP/6-31g* irc=(calcfc,maxpoints=200,forward) optcyc=99
!input geometry should be a transition state

IRC (Intrinsic Reaction Coordinate) job, forward path

0 1
 c
 c   1 cc2     
 c   1 cc3        2 ccc3      
 h   1 hc4        2 hcc4         3 dih4   
 h   2 hc5        1 hcc5         3 dih5   
 h   3 hc6        1 hcc6         2 dih6   
 f   3 fc7        1 fcc7         2 dih7   
variables
cc2         1.374669
cc3         1.374731
ccc3         59.977
hc4         1.079934
hcc4        145.790
dih4       -148.053
hc5         1.077596
hcc5        150.630
dih5       -158.408
hc6         1.077585
hcc6        150.610
dih6        158.533
fc7         1.945294
fcc7         99.713
dih7        -59.187

