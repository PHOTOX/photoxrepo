%NprocShared=2
%Mem=500Mb
#B3LYP/6-31g* opt=QST2 freq 

finding transition state using qst2,geometry of reactant goes first

0 1
 c
 c   1 cc2     
 c   1 cc3        2 ccc3      
 h   1 hc4        2 hcc4         3 dih4   
 h   2 hc5        1 hcc5         3 dih5   
 h   3 hc6        1 hcc6         2 dih6   
 f   3 fc7        1 fcc7         2 dih7   
variables
cc2         1.307449
cc3         1.471901
ccc3         63.629
hc4         1.080805
hcc4        149.153
dih4       -176.960
hc5         1.080771
hcc5        149.272
dih5        176.701
hc6         1.090176
hcc6        124.257
dih6        109.730
fc7         1.394168
fcc7        119.114
dih7       -105.996

product

0 1 
 c
 c   1 cc2     
 c   1 cc3        2 ccc3      
 h   1 hc4        2 hcc4         3 dih4   
 h   2 hc5        1 hcc5         3 dih5   
 h   3 hc6        1 hcc6         2 dih6   
 f   2 fc7        1 fcc7         3 dih7   
variables
cc2         1.471921
cc3         1.307530
ccc3         63.611
hc4         1.080776
hcc4        147.147
dih4       -177.145
hc5         1.090053
hcc5        124.353
dih5       -109.844
hc6         1.080823
hcc6        149.197
dih6       -176.877
fc7         1.394716
fcc7        119.011
dih7        105.980

