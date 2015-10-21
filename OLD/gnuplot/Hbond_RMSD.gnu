# This script creates multiplot of various MD structural parameters vs. time

reset
set terminal postscript enhanced portrait color "Arial" 10 solid
# set term png size 1024, 1280
############SETUP##########################
set output "RMSD_HBOND_GAAA.eps"
set title "{/*1.5 H-bonds in GAAA[bsc0jp] tetraloop}"
set xrange [0:100.]
######################################
set encoding iso_8859_1

set multiplot
set size 1.0,0.25
set origin 0.0,0.75 
set ylabel "Distance (\305)"
set grid
set key top
set format y "%3.0f"
set bmargin 0.5
set ytics 2 
set ytics add ("3.5" 3.5) 
#set tmargin 0.5  

f(x)=x*(0.002)
#H-bonds in tetraloop

plot 'G5N2-A8O2P.dat' using (f($1)):2 t 'j-1(N2) to j+2(O2P)' with lines
#

unset title
set tmargin
set origin 0.0,0.5
plot 'G5N2-A8N7.dat' using (f($1)):2 t 'j-1(N2) to j+2(N7)'  lt 2 with lines
#
set bmargin
set xlabel "Time (ns)"
set origin 0.0,0.25
plot 'G5O2´-A7N7.dat' using (f($1)):2 t 'j-1(O2´) to j+1(N7)' lt 12 with lines 


f(x)=x*(0.001)
#
#Root-mean-square-deviation of backbone atoms as a function of time 
set title "{/*1.5 Root-mean-square-deviation of backbone atoms as a function of time}"

#set bmargin 0.5
set origin 0.0,0.0 
unset key
#set ytics auto
#set format y "%3.0f"
set ytics 1 
set ylabel "RMSD (\305)"
plot 'backbone.rms' using (f($1)):2 t 'RMSD' with lines 

#
unset multiplot
pause -1 "Hit return to continue"
#
reset

# HELP 
#     set terminal postscript {landscape | portrait | eps}
#                             {enhanced | noenhanced}
#                             {defaultplex | simplex | duplex}
#                             {fontfile [add | delete] "<filename>"
#                              | nofontfiles}
#                             {level1 | leveldefault}
#                             {color | colour | monochrome}
#                             {solid | dashed}
#                             {dashlength | dl <DL>}
#                             {linewidth | lw <LW>}
#                             {rounded | butt}
#                             {palfuncparam <samples>{,<maxdeviation>}}
#                             {size <XX>{unit},<YY>{unit}}
#                             {blacktext | colortext | colourtext}
#                             {{font} "fontname{,fontsize}" {<fontsize>}}
