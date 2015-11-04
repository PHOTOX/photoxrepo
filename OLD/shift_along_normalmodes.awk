#takes molpro output and prepares molpro input with distorted geometry along each normal mode
BEGIN{
n=15		#normal mode, along which we are moving
j=2
#equilibrium geometry
K0[1]=0.00000000
K0[2]=0.00000000
K0[3]=0.00000000
K0[4]=0.00000000
K0[5]=0.00000000
K0[6]=1.31771243
K0[7]=0.00000000
K0[8]=1.37495530
K0[9]=0.65885139
K0[10]=0.00029872
K0[11]=-0.54669273
K0[12]=-0.93889916
K0[13]=-0.00033685
K0[14]=-0.54665405
K0[15]=2.25663352
K0[16]=-0.92317855
K0[17]=1.96842289
K0[18]=0.65881538
K0[19]=0.92320269
K0[20]=1.96834958
K0[21]=0.65891290
}
{

if ( $1 == "Intensities" && $2 == "[relative]" ) {
	if ( j != "0" ) {
		j=j-1
		next
	}
        for (h=1;h<=21;h++) {
		getline
		K[h]= $6
        	print K[h]
	}
	exit 0
        }

}
END{
for ( i=-3;i<=3;i++) {

l=0.2*i
if ( i==0 ) continue
for ( k=1; k<=21;k++) {  
	R[k] = K0[k] + K[k]*l 
}
#for (k=10;k<=21;k=k+3) { 
#	K[k]=HX0[k] + K[k]*l
#	K[k]=HY0[k] + K[k+1]*l
#	K[k]=HZ0[k] + K[k+2]*l


OFMT = "%4.5f"
print "print,civector  \n\
memory,150,m; \n \
!geometry optimized with mp2/aug-cc-pVDZ\n\
!geometry plus "i"*normal mode number "n"\n \
 geometry={\n\
 nosymm,noorient,angstrom" > ("mode" n "_" i ".com")
print "C,, ",R[1],",",R[2],",",R[3] > ("mode" n "_" i ".com")
print "C,, ",R[4],",",R[5],",",R[6] > ("mode" n "_" i ".com")
print "C,, ",R[7],",",R[8],",",R[9] >("mode" n "_" i ".com")
print "H,,",R[10],",",R[11],",",R[12] > ("mode" n "_" i ".com")
print "H,,",R[13],",",R[14],",",R[15] > ("mode" n "_" i ".com")
print "H,,",R[16],",",R[17],",",R[18] > ("mode" n "_" i ".com")
print "H,,",R[19],",",R[20],",",R[21] > ("mode" n "_" i ".com")
print " }" > ("mode" n "_" i ".com") 
print "basis=aug-cc-pVDZ \n \
hf \n \
{ccsd \n \
eom,-5.1,trans=2} " >> ("mode" n "_" i ".com")
print "~/bin/runM06 mode"n"_"i".com" > ( "run.mode" )
}
}
