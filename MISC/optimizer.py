#!/usr/bin/env python
#Python script for optimizing molecule under constraints
#v0.51 GAUSSIAN
#MANUAL: https://www.overleaf.com/read/dnvcntdyzxsd

#Using atomic units (bohr radius, hartree)
#If both coniditions are demanded, first the distance is fixed and then dipole constraint is turned on

from optparse import OptionParser
import math
import numpy as np
import os,sys
import subprocess

#Redirecting output to file (uncomment)
#sys.stdout=open("output","w+",0)

# Some constants
angtobh = 1.889716


# I/O xyz files
def read_xyz(filename):
    """Read filename in XYZ format and return lists of atoms and coordinates."""
    #print('Reading geom from:'),filename
    atoms = []
    coordinates = []
	
    xyz = open(filename)
    n_atoms = int(xyz.readline())
    title = xyz.readline()
    for line in xyz:
	if len(line.strip()) == 0:
		pass
		break	
	atom,x,y,z = line.split()
	atoms.append(atom)
	coordinates.append([float(x), float(y), float(z)])
    xyz.close()
    coordinates = [[w * angtobh  for w in ww] for ww in coordinates] #ang to bh

    if n_atoms != len(coordinates):
 	print('Number of atoms in xyz file doesnt equal to the number of lines.')
	sys.exit(1)
 
    return atoms, coordinates

def print_xyz(atoms,coordinates,filename):
    """"Prints XYZ coordinates into a target file."""
    coordinates = [[w / angtobh for w in ww] for ww in coordinates] #bh to ang
    xyz = open(filename,"a")
    xyz.write(str(len(atoms)))
    xyz.write("\nOptimizer geometry\n")
    for i in xrange(len(atoms)):
	xyz.write(atoms[i] + ' ')
	xyz.write(" ".join(str(f) for f in coordinates[i]))
	xyz.write("\n")
    coordinates = [[w * angtobh  for w in ww] for ww in coordinates] #ang to bh
    xyz.close()


# Main program
def main():
    maxforce = 0.00015      # Criterion for SD only
    maxenergydiff = 0.000001 # Criterion SD with constraint
   
    diptoau = 1 / 4.798    # 1D = 0.20819434 e.Ang
    dipgradtoau =  1 / 1.88972 # gauss dipole grad is e.ANG-1
    coordinates_prev = []
    force_grad = []
    force_grad_pure = []
    dipole_holder = []
    dipole_holder2 = []
    dipole_grad = []
    dipole_xyz = []
    hess_matrix = []
    en = []
    co1 = []
    co2 = []
    co1_lagrange = 0
    co2_lagrange = 0
    dipole = 0 #
    
    print('')
    print('Molecule optimization under constraints')
    print('Optimizing under (1) distance constraint and (2) dipole moment constraint')
    print('')

    #Parser
    usage = "usage: %prog [options]"
    """Function for reading command line options. Returns tuple options, args."""
    parser = OptionParser(usage)
    parser.add_option('-g','--geometry',dest='geom', type='string',default='geom.xyz', help='Input geometry for optimization.')
    parser.add_option('--distatoms',dest='datoms', type='int', nargs=2, help='Distance constraint target atoms: atom1 atom2')
    parser.add_option('--distvalue',dest='con1',type='float',help='Distance constrinat (distance ang)')
    parser.add_option('--dipole',dest='con2',type='float', help='Dipole constraint (dipole debye)')
    parser.add_option('--hess' ,dest='hess',action='store_true', default='False', help='Use hessian for convergence once the conditions are met.')
    #parser.add_option('--maxforce',dest='maxforce',type='float',default='0.00015',help='Force convergence criterion') 

    (options, args) = parser.parse_args(sys.argv)

    print('=======================================')
    if (options.con1 is None) and (options.con2 is None): 
        print('Ex: python optimizer.py --geom geom.xyz --distatoms 3 12 --distvalue 0.98 --dipole 4.0 \n')
    	parser.print_help()
	print('RUNNING steepest descent algorithm w conjugate gradients')
    else:
	print('RUNNING optimization algorithm under constraint(s)')

    if (options.con2 is not None) and  (options.con1 is not None): #Flag for computing frequencies (req. for dipole gradient)
        flag = 0
    elif (options.hess is True) or (options.con2 is not None):
	flag = 1
    else:
        flag = 0
    
    #Reading geometry
    atoms,coordinates = read_xyz(options.geom)
    print_xyz(atoms,coordinates,"movie.xyz")
 
    #Cleanup
    try:
	os.remove("./movie.xyz")    
	os.remove("./stats.out")
	os.remove("./calc.chk")
    	os.remove("./final.xyz")
    except OSError:
    	pass


    stats = open("stats.out","a",0)

    #---Starting an optimization loop---
    i = 0
    while True:
	#Compute gradients (input files: GAUSSIAN)
	file = open("input.com","w+")
 	file.write("%nprocshared=1 \n")
	file.write("%chk=calc.chk \n")
	if flag == 1:
        	file.write("#HF/6-31g* Freq guess=(Read,TCheck) NoSymm \n\n")	#Freq	(nosymm required for correct dipole gradient orientation) #GAUSSIAN INPUT PARAMETERS
	else:
		file.write("#HF/6-31g* Force guess=(Read,TCheck) NoSymm \n\n")     #Force
	file.write("#Optimizer script input file step %d \n\n" % i)
	file.write("0   1\n")
	coordinates = [[w / angtobh for w in ww] for ww in coordinates] #bh to ang
	for j in xrange(len(atoms)):
		file.write("%s " % atoms[j])
		file.write(" ".join("%.6f" % f for f in coordinates[j]))
		file.write("\n")
	coordinates = [[w * angtobh for w in ww] for ww in coordinates] #ang to bh
	file.write("\n")
	file.close()
    
	process = subprocess.Popen("GAUSS input.com", shell=True, stdout=subprocess.PIPE)
	process.wait()
	if process.returncode != 0:
		print('GAUSSIAN calculation failed!')
		sys.exit(1)
	
	#Load gradients
 	file = open("input.log","r")

	force_grad_old = force_grad
        force_grad = []
	force_grad_pure = []

	for line in file:
		if 'SCF Done:' in line:
		    for j in line.split():
   			 try:
			     en.append(float(j))
       			     energy=float(j)
			     break
   			 except ValueError:
        		     pass

                if 'Forces (Hartrees/Bohr)' in line:
                    for line in file:
                        break 
                    for line in file:
			break
		    for line in file:
			if line[1] == '-':
				break
			a1,a2,fx,fy,fz = line.split()
			force_grad.append([float(fx), float(fy), float(fz)])
	file.close()
	force_grad_pure = force_grad
	stats.write(str(energy) + '   ')	
	
	#Load dipole gradients (Gaussian e.ang)
	if (options.con2 is not None):
	   dipole_xyz = []
	   dipole_holder = []
	   dipole_holder2 = []
	   dipole_grad = []

	   if flag == 1:
	     with open('input.log', 'r') as file:
           	data=file.read().replace('\n', '')
		data=data.replace(' ', '')
	   	sub1 = data.split("DipoleDeriv=")	
	   	sub2 = sub1[1].split("\Polar")
		sub3 = sub2[0]
		dipole_holder = [float(j) for j in sub3.split(",")]
 	     file.close()
	
	     j=0
	     while j < len(dipole_holder):
		dipole_holder2.append(dipole_holder[j:j+3])
		j+=3
	     j=0
             while j < len(dipole_holder2):
                dipole_grad.append(dipole_holder2[j:j+3])
                j+=3

           file = open("input.log","r")
	   for line in file:
                if ' Dipole moment' in line:
                    for line in file:
			lines = line.split()
			dipole = float(lines[7])
			dipole_xyz.append(float(lines[1]))
			dipole_xyz.append(float(lines[3]))
			dipole_xyz.append(float(lines[5]))
			break
	   file.close()

	#Load hessian matrix
	if flag == 1:
		process = subprocess.Popen("echo calc.chk | /home/slavicek/G03/gaussian09/d01/arch/x86_64_sse4.2/g09/formchk", shell=True, stdout=subprocess.PIPE)
	        process.wait() 		#Formatting the checkpoint file
       		if process.returncode != 0:
                	print('GAUSSIAN calculation failed!')
                	sys.exit(1)

		hess_matrix = []
		hess_holder = []
		hesselements = (1+3*len(atoms))*3*len(atoms)/2
		hessx = len(atoms)*3

		with open('calc.fchk', 'r') as file:
			data=file.read().replace('\n', ' ')
			sub1 = data.split("Cartesian Force Constants")
                	sub1[1] = sub1[1].replace(' ', ',')
			sub2 = sub1[1].split(str(hesselements)+',,')
			sub3 = sub2[1].split("Dipole")
			sub4 = sub3[0]
			sub4 = sub4.replace(',', ' ')
                	hess_holder = [float(j) for j in sub4.split()]
	        file.close()

		#Fill the lower triangle (Gaussian format)
		hess_matrix = np.eye(hessx)		
		i_low,j_low = np.tril_indices(hessx)
		hess_matrix[i_low,j_low] = hess_holder
		#Now upper 
		i_up = np.triu_indices(hessx, 1)
		hess_matrix[i_up] = hess_matrix.T[i_up]


	if i == 0:
	   beta = 0.001
	   gamma = 0.05
	#Evaluators
        # 1 - constant bond length (Bohr is default) 
        if options.con1 is not None:
                atom1 = options.datoms[0]
                atom2 = options.datoms[1]
                targetdist = options.con1 * angtobh

                coord1 = np.asarray(coordinates[atom1-1])
                coord2 = np.asarray(coordinates[atom2-1])
                diff = np.linalg.norm(coord2-coord1)
                deltaLen = diff - targetdist
                co1.append(abs(deltaLen))
                print('   [%d] Distance %f Target %f Beta %f' % (i, diff / angtobh, targetdist / angtobh, beta))
	# 2 - dipole moment constraint (Debye is default)
        if (options.con2 is not None):
                targetdipole = options.con2

                deltaDip = dipole - targetdipole
                co2.append(abs(deltaDip))
                print('   [%d] Dipole %f Target %f Gamma %f' % (i, dipole, targetdipole, gamma))

        
	#Adapting alpha
	if i > 0:
		if ((options.con1 is None) and (options.con2 is None)): 	#Steepest descent only
			if en[-1] < en[-2]:
				alpha = 1.2 * alpha
			else:
				alpha = 0.5 * alpha
		if (options.con1 is not None): 					#Distance constraint
			if co1_lagrange == 1:
			   if en[-1] < en[-2]:
                               	alpha = 1.2 * alpha
                           else:
                               	alpha = 0.5 * alpha
			else:
			   if (co1[-1] < co1[-2]) and not (abs(deltaLen) < 0.02):
				if ((co1[-2]-co1[-1]) > (0.04 * angtobh)):
					alpha = 0.7 * alpha
				elif ((co1[-2]-co1[-1])<(0.025 * angtobh)):
					alpha = 1.2 * alpha
					beta = 1.05 * beta
				else:
					pass
			   elif (abs(deltaLen) < 0.1):
			 	if alpha > 1: aplha = 1
				beta = 1.075 * beta 
			   else:
				alpha = 1
				beta = 1.05 * beta
		if (options.con2 is not  None):					  #Dipole constraint
			if co2_lagrange == 1:
			   if en[-1] < en[-2]:
                                alpha = 1.2 * alpha
                           else:
                                alpha = 0.5 * alpha
			   #if alpha > 1.0:
			   #	alpha = 1.0	
			elif (options.con1 is not None) and (co1_lagrange == 0):	#after distnace fits
			   pass
			else:
			   if (co2[-1] < co2[-2]) and not (abs(deltaDip) < 0.15):
				if ((co2[-2]-co2[-1]) > 0.5):
					alpha = 0.7 * alpha
				elif ((co2[-2]-co2[-1]) < 0.1):
					alpha = 1.2 * alpha
					gamma = 1.05 * gamma
				else:
					pass                                
			   elif (abs(deltaDip) < 0.15):
				if alpha > 1: aplha = 1
				gamma = 1.075 * gamma
                           else:
				alpha = 1 
				gamma = 1.05 * gamma

		if alpha > 2:
			alpha = 2
		if alpha < 0.1:
			alpha = 0.1
		if beta > 2:
			beta = 2
	 	if gamma > 2:
			gamma = 2

	else:
		alpha = 1

        #Constraints
	# 2 - dipole moment constraint TODO: as a function
	if (options.con2 is not None):
	 if (options.con1 is not None) and (co1_lagrange == 0):		#turn on after distance fits
	   stats.write(str(dipole) + '   ')
	   print('Converging distance constraint first')
	 else:
		if (abs(deltaDip) < 0.075):
			co2_lagrange = 1
                if (options.hess is True) and (abs(deltaDip) < 0.25): #Lower threshold for hess, it can handle the exact convergence
                        co2_lagrange = 1

	
		if (co2_lagrange == 1) and (options.hess is not True):
                # Method of lagrange multipliers
			l = 0
		 	while True:	
			   lsum = 0
			   dipole_new = 0
			   dipole_new_x = 0
			   dipole_new_y = 0
			   dipole_new_z = 0
			   for j in xrange(len(atoms)):			#we dont take into account other constraints, force prediction is inevitably bad 
                      		for k in range(0,3):
				   dipole_new_x = dipole_new_x + (dipole_grad[j][0][k]) *  alpha * force_grad[j][k] * 0.52917
                                   dipole_new_y = dipole_new_y + (dipole_grad[j][1][k]) *  alpha * force_grad[j][k] * 0.52917	
                                   dipole_new_z = dipole_new_z + (dipole_grad[j][2][k]) *  alpha * force_grad[j][k] * 0.52917
                           dipole_new = math.sqrt((dipole_xyz[0]+dipole_new_x/diptoau)**2 + (dipole_xyz[1]+dipole_new_y/diptoau)**2 + (dipole_xyz[2]+dipole_new_z/diptoau)**2)


			   for j in xrange(len(atoms)):
                                for k in range(0,3):
				   lsum = lsum + (dipgradtoau * ( dipole_xyz[0] * dipole_grad[j][0][k] + dipole_xyz[1] * dipole_grad[j][1][k] +  dipole_xyz[2] * dipole_grad[j][2][k] )/(dipole))**2
			   #lambd = - (deltaDip)/(lsum * alpha)
			   lambd = - (dipole_new - targetdipole) / (lsum * alpha)			

			   for j in xrange(len(atoms)):
	                      	for k in range(0,3):
				   force_grad[j][k] = force_grad[j][k] + lambd * diptoau * (dipgradtoau * ( dipole_xyz[0] * dipole_grad[j][0][k] + dipole_xyz[1] * dipole_grad[j][1][k] + dipole_xyz[2] * dipole_grad[j][2][k] )/(dipole))
				   #dipole_new = dipole_new + ((0.393456 * dipole_xyz[0] * dipole_grad[j][0][k] + 0.393456 * dipole_xyz[1] * dipole_grad[j][1][k] + 0.393456 * dipole_xyz[2] * dipole_grad[j][2][k] )/(0.393456 * dipole)) * alpha * force_grad[j][k]
			   print dipole_new 
			  
			   deltaDip = dipole_new - targetdipole 
			   if abs(deltaDip) < 0.00001:
                           	break

			print('   Lagrange multipliers - dipole Con2, lambd: %f' % (lambd)) 	

		else:
		# Constraint for approach
		   for j in xrange(len(atoms)):
		      for k in range(0,3):
			force_grad[j][k] = force_grad[j][k] - gamma * deltaDip * diptoau * (dipgradtoau * (dipole_xyz[0] * dipole_grad[j][0][k] +  dipole_xyz[1] * dipole_grad[j][1][k] +  dipole_xyz[2] * dipole_grad[j][2][k] )/( dipole)) 

		stats.write(str(dipole) + '   ')

	# 1 - constant bond length    TODO: as a function
	if options.con1 is not None:
		if (abs(deltaLen) < 0.02): #Bh	Accurate threshold - the value will stick exactly
                	co1_lagrange = 1   
			if (options.con2 is not None): flag = 1 
		if (options.hess is True) and (abs(deltaLen) < 0.25): #Lower threshold for hess, it can handle the exact convergence
			co1_lagrange = 1
                        flag = 1

		if (co1_lagrange == 1) and (options.hess is not True):
		# Method of lagrange multipliers
		  print('   Lagrange multipliers - distance Con1')
                  while True: 
		   for j in range(0,3):
			force_grad[atom1-1][j] = force_grad[atom1-1][j] -  0.5 * (1/targetdist**2) * (diff**2 * (force_grad[atom1-1][j] - force_grad[atom2-1][j]))
			force_grad[atom2-1][j] = force_grad[atom2-1][j] -  0.5 * (1/targetdist**2) * (diff**2 * (force_grad[atom2-1][j] - force_grad[atom1-1][j]))
			epsilon = math.sqrt((diff * (force_grad[atom2-1][j] - force_grad[atom1-1][j]))**2)
		   #print('   Lagrange multipliers - distance Con1, epsilon: %f' % (epsilon))
		   if epsilon < 0.00000001:
			break
		else:
		# Constraint for approach
		   for j in range(0,3):
			pass
			force_grad[atom1-1][j] = force_grad[atom1-1][j] + beta * deltaLen * (coordinates[atom2-1][j]-coordinates[atom1-1][j] ) 
                        force_grad[atom2-1][j] = force_grad[atom2-1][j] + beta * deltaLen * (coordinates[atom1-1][j]-coordinates[atom2-1][j] )
		
		stats.write(str(diff/angtobh) + '   ')

	stats.write("\n")
        #MAKING THE STEP
	#Conjugate descent parameters
	norm = np.linalg.norm(np.asarray(force_grad))
	conjug = np.linalg.norm(np.absolute(np.asarray(force_grad)), ord=2)**2 / np.linalg.norm(np.absolute(np.asarray(force_grad_old)), ord=2)**2
	#Hessian step
	if (options.hess is True) and (len(hess_matrix) != 0) and ( ((options.con1 is not None) and (co1_lagrange == 1) and (options.con2 is None)) or ((options.con2 is not None) and (co2_lagrange == 1) and (options.con1 is None)) or ((options.con1 is not None) and (options.con2 is not None) and (co1_lagrange == 1) and (co2_lagrange == 1)) or (options.con1 is None and options.con2 is None)):    #Turn on after we use LM method or 'no constraints' with --hess 
		print('   HESSIAN step')
		#TRUSTED REGION parameters
		#alphavec = np.empty((3*len(atoms),1))
                #alphavec.fill(alpha)
                eig = np.linalg.eigvals(hess_matrix)
                scal = max(0,-min(eig)) * 1.1
                TREGhess = np.add(hess_matrix, scal * np.eye(3*len(atoms))) #trusted region, we have to use this because Hessian is not positive definite
									    #this procedure at least makes all eigenvalues positive
                alpha_hess =  - np.dot(np.linalg.pinv(TREGhess),-np.asarray(force_grad_pure).flatten()) # + H-1*f_i

		#Alpha with hessian (step prediction)
                while True:
                  if np.max(np.absolute(alpha * alpha_hess)) > (1.0 * angtobh):        #Greater step than 0.15 Ang
                        alpha = alpha * 0.75
                  else:
                        break
	
		#CONSTRAINTS: CERN's Data Analysis BriefBook Page 88
		if (options.con1 is not None) or (options.con2 is not None):
		 o = 0
		 while True:
		  B = [] # constraint gradients
		  C = [] # constraint values
		  LMDgrad = []
		  #Hess constrain BOND 
		  if (options.con1 is not None):
			#Predicted bond length
			alpha_hess = np.reshape(alpha_hess,(len(atoms),3))
			nextcoord1 = np.add( alpha * alpha_hess[atom1-1], np.asarray(coordinates[atom1-1]))
			nextcoord2 = np.add( alpha * alpha_hess[atom2-1], np.asarray(coordinates[atom2-1]))
			alpha_hess = alpha_hess.flatten()
			###nextLen = np.linalg.norm(nextcoord2-nextcoord1)**2 - targetdist**2
			nextLen = diff**2 - targetdist**2 #we expand around C0
			C.append(nextLen)

			#B gradient
			LMgrad = []
	                for j in xrange(len(atoms)):
				if (j != (atom1-1)) == (j != (atom2-1)):
					for k in range(0,3):
						LMDgrad.append(0)
				elif j == (atom1-1):
					for k in range(0,3):
						LMDgrad.append(2 * (coordinates[atom1-1][k]-coordinates[atom2-1][k]) * 1)
				elif j == (atom2-1):
					for k in range(0,3):
						LMDgrad.append(2 * (coordinates[atom1-1][k]-coordinates[atom2-1][k]) * (-1))
			B.append(LMDgrad)

		  #Hess constraint DIPOLE
		  if (options.con2 is not None):
                        C.append((dipole*diptoau)**2 - (targetdipole*diptoau)**2)
			#C.append(deltaDip*diptoau)

                        #B gradient
                        LMgrad = []
                        for j in xrange(len(atoms)):
                                for k in range(0,3):
                                        LMgrad.append(2 * dipgradtoau * diptoau *( dipole_xyz[0] * dipole_grad[j][0][k] + dipole_xyz[1] * dipole_grad[j][1][k] +  dipole_xyz[2] * dipole_grad[j][2][k]) )
					#LMgrad.append(1 * dipgradtoau * ( dipole_xyz[0] * dipole_grad[j][0][k] + dipole_xyz[1] * dipole_grad[j][1][k] +  dipole_xyz[2] * dipole_grad[j][2][k] )/(dipole))
                        B.append(LMgrad)

	 
		  #Compute new hessian shift
		  B = np.asarray(B)
		  C = np.asarray(C)

		  alpha_hess = np.subtract(alpha_hess, np.dot(np.linalg.pinv(TREGhess),np.dot(B.T,np.dot( np.linalg.pinv(alpha*np.dot(B,np.dot(np.linalg.pinv(TREGhess),B.T))),(np.add(C,alpha*np.dot(B,alpha_hess))))))) 
		  #alpha_hess = np.subtract(alpha_hess, np.dot(np.linalg.inv(hess_matrix),np.dot(B.T,np.dot( np.linalg.inv(alpha*np.dot(B,np.dot(np.linalg.inv(hess_matrix),B.T))),(np.add(C,alpha*np.dot(B,alpha_hess)))))))
		  alpha_hess = np.reshape(alpha_hess,(len(atoms),3))

		  #Check the convergence
 		  if (options.con1 is not None):
			nextcoord1 = np.add(alpha * alpha_hess[atom1-1], np.asarray(coordinates[atom1-1]))
                        nextcoord2 = np.add(alpha * alpha_hess[atom2-1], np.asarray(coordinates[atom2-1]))
                        nextLen = np.linalg.norm(nextcoord2-nextcoord1)**2 - targetdist**2
			#print nextLen/angtobh
			if abs(nextLen/angtobh) < 0.00001:
				break

                  if (options.con2 is not None):
			dipole_new = 0
                        dipole_new_x = 0
                        dipole_new_y = 0
                        dipole_new_z = 0
                        for j in xrange(len(atoms)):                 
                          for k in range(0,3):
                              dipole_new_x = dipole_new_x + (dipole_grad[j][0][k]) *  alpha * alpha_hess[j][k] * dipgradtoau
                              dipole_new_y = dipole_new_y + (dipole_grad[j][1][k]) *  alpha * alpha_hess[j][k] * dipgradtoau
                              dipole_new_z = dipole_new_z + (dipole_grad[j][2][k]) *  alpha * alpha_hess[j][k] * dipgradtoau
                        dipole_new = math.sqrt((dipole_xyz[0]+dipole_new_x/diptoau)**2 + (dipole_xyz[1]+dipole_new_y/diptoau)**2 + (dipole_xyz[2]+dipole_new_z/diptoau)**2)
			print dipole_new
			#print (dipole_new - targetdipole)
			if abs(dipole_new - targetdipole) < 0.001: 
				break

		  alpha_hess = alpha_hess.flatten()
		  #break
		  o = o+1
		  if o > 5: break

		#STEP
		alpha_hess = np.reshape(alpha_hess,(len(atoms),3))
		for j in xrange(len(atoms)):
	  	   for k in range(0,3):
		       coordinates[j][k] = coordinates[j][k] + alpha * alpha_hess[j][k]
		
		norm = np.linalg.norm(np.asarray(force_grad))
		print('Step [%d] : energy [%f] norm [%f] alpha [%f]' % (i, energy, norm, alpha))
		if (options.con1 is not None) or (options.con2 is not None): alpha = 1
	else:
	#Conjugate gradient / Steepest descent
                while True:
                  if np.max(np.absolute(alpha * np.asarray(force_grad))) > (0.05 * angtobh):        #Greater step than 0.15 Ang
                        alpha = alpha * 0.75
                  else:
                        break

		for j in xrange(len(atoms)):
                   for k in range(0,3):
		      if (i > 0)  and (co2_lagrange == 0): force_grad[j][k] = force_grad[j][k] + conjug * force_grad_old[j][k] #Conjugated gradients
		      coordinates[j][k] = coordinates[j][k] + alpha  * force_grad[j][k]					    #Gradient descent
		print('Step [%d] : energy [%f] norm [%f] alpha [%f]' % (i, energy, norm, alpha))

	print_xyz(atoms,coordinates,"movie.xyz")


	if i > 0:
	 if (options.con1 is None) and (options.con2 is None):           #Steepest descent only
	  if (norm/len(atoms) < maxforce) and (abs(en[-1]-en[-2]) < maxenergydiff):
		print('#FINISHED - optimal geometry found -')
		print_xyz(atoms,coordinates_prev,"final.xyz")
		break
	 elif (options.con1 is not None) and (options.con2 is None):       #Distance constraint
	  if (co1_lagrange == 1) and abs(en[-1]-en[-2]) < maxenergydiff and np.max(np.absolute(np.asarray(force_grad))) < maxforce:
		print('#FINISHED - optimal geometry with distance constraint found -')	
		print_xyz(atoms,coordinates_prev,"final.xyz")
		break
	 elif (options.con1 is None) and (options.con2 is not None):	#Dipole  constraint
   	  if (co2_lagrange == 1) and abs(en[-1]-en[-2]) < maxenergydiff and np.max(np.absolute(np.asarray(force_grad))) < maxforce:
                print('#FINISHED - optimal geometry with dipole constraint found -')
                print_xyz(atoms,coordinates_prev,"final.xyz")
                break
	 else:
	  if (options.hess is True) and (co1_lagrange == 1) and (co2_lagrange == 1) and abs(en[-1]-en[-2]) < 0.00001 and (abs(deltaDip) < 0.05) and (abs(deltaLen) < 0.05):
		print('#FINISHED - optimal geometry with distance and dipole constraint found -')
		print_xyz(atoms,coordinates_prev,"final.xyz")
		break
	  elif (co1_lagrange == 1) and (co2_lagrange == 1) and abs(en[-1]-en[-2]) < maxenergydiff and np.max(np.absolute(np.asarray(force_grad))) < maxforce:
                print('#FINISHED - optimal geometry with distance constraint found -')
                print_xyz(atoms,coordinates_prev,"final.xyz")
                break

	coordinates_prev = coordinates
	i += 1
	#break
	if i>5000:
		print('5000 steps reached, most likely you have a convergence problem, terminating') 
		break

    stats.close()
    sys.stdout.close()

if __name__ == '__main__':
   main()



