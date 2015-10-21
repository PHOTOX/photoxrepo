      program ci_search 
C ---------------------------------------------------------
C  Program for conical intersection search 
C  Employs Lagrange-Newton method of Manaa and Yarkony, JCP 99 (1993) 5251 
C  Molpro program package used for energy, gradient and non-adiabatic coupling calculations
C  So far only for singlet-singlet crossing
C
C  File 'script_for_molpro' contains sample for Molpro calculation
C
C  v1.01: More clever Hessian implemented (JPCA 2004, 108, 3200)
C
C-----------------------------------------------------------  
      implicit real*8(a-h,o-z)
      parameter(num=3500)
      dimension r(num),q(num,num),aa(num,num),b(num),dx(num) 
      dimension hij(num),gi(num),gj(num),gij(num)
      character*2 atom(num) 
      real*8 ksi1,ksi2
      integer main
      logical gap,change

      open(21,file='input') 

      read(21,*)
      read(21,*)gthresh
      read(21,*)ethresh
      read(21,*)maxit
      read(21,*)thresh

      factor=3.

      close(21)

      open(201,file='output') 
      write(201,*)'** CI-SEARCH program output **'
      write(201,*)
      write(201,*)'Convergence criteria:'
      write(201,1003)'Gap threshold (eV)              :',gthresh
      write(201,1003)'Energy change threshold (eV)    :',ethresh
      write(201,*)
      write(201,*)'Maximum number of iterations    :',maxit
      write(201,1003)'Maximum CI splitting (eV)       :',thresh
      write(201,*)
      write(201,*)'Step No.     E1 (a.u.)       E2 (a.u.)       Gap (eV)  
     &      Gap conv.    En. conv.'

1003  format(A34,F12.8)

      close(201)

      thresh=thresh/27.2117
      gthresh=gthresh/27.2117
      ethresh=ethresh/27.2117

      ei=0.
      ej=0.

C GEOMETRY INPUT

c mini.dat should contain minimum energy structure in a molden format 
      open(111,file='mini.dat') 

      read(111,*)natom
      read(111,*)
      do i=1,natom
        j=(i-1)*3+1
        read(111,*)atom(i),r(j),r(j+1),r(j+2)
      enddo

      close(111)

      ksi1=1.
      ksi2=1.

      n=natom*3

c Q MATRIX INITIALLY APPROXIMATED AS Q==1

      do i=1,n
       do j=1,n
         q(i,j)=0.
         if(i.eq.j) q(i,j)=1.
       enddo
      enddo

c MAIN LOOP

      do main=1,maxit

C GEOMETRY UPDATE

      open(121,file='geom.last') 
      do i=1,natom
        j=(i-1)*3+1
        write(121,1001)atom(i),',,',r(j),r(j+1),r(j+2)
      enddo
      close(121)
1001  format(A4,A2,3F18.12)

c MOLPRO CALCULATION AND READING

      eiold=ei
      ejold=ej

      call system('./script_for_molpro')

      open(131,file='data.vectors') 
      read(131,*)ei
      read(131,*)ej
      de=ej-ei
      do i=1,natom
        j=(i-1)*3+1
        read(131,*)junk,hij(j),hij(j+1),hij(j+2)
      enddo
      do i=1,natom
        j=(i-1)*3+1
        read(131,*)junk,gi(j),gi(j+1),gi(j+2)
      enddo
      do i=1,natom
        j=(i-1)*3+1
        read(131,*)junk,gj(j),gj(j+1),gj(j+2)
      enddo

      close(131)
   
      do i=1,n
        gij(i)=gj(i)-gi(i)
      enddo

c Newton-Rhapson procedure: Matrix construction

      do i=1,n
       do j=1,n
        aa(i,j)=q(i,j)
       enddo 
      enddo 

      do i=1,n
        aa(n+1,i)=2*gij(i)
        aa(i,n+1)=2*gij(i)
        aa(n+2,i)=hij(i)
        aa(i,n+2)=hij(i)
      enddo 

      aa(n+1,n+1)=0.
      aa(n+2,n+1)=0.
      aa(n+1,n+2)=0.
      aa(n+2,n+2)=0.

      do i=1,n
        b(i)=-((gi(i)+gj(i))/2.+ksi1*gij(i)+ksi2*hij(i))
      enddo

      b(n+1)=-de
      b(n+2)=0. 

      if (de.gt.thresh) then
        b(n+1)=thresh
c        write(*,*)"Too large gap - changed to ",thresh*27.2117," eV" 
      endif

c Gaussian elimination with back-substition

      do i=1,n+1
       do j=i+1,n+2
        faktor=aa(j,i)/aa(i,i)
        do k=i,n+2
          aa(j,k)=aa(j,k)-faktor*aa(i,k)
c          write(*,*)j,k,aa(j,k),faktor
        enddo
        b(j)=b(j)-faktor*b(i)
c        write(*,*)j,b(j)
       enddo
      enddo

      dx(n+2)=b(n+2)/aa(n+2,n+2)

      do i=n+1,1,-1
        sum=0.
        do j=i+1,n+2
          sum=sum+aa(i,j)*dx(j)
        enddo 
        dx(i)=(b(i)-sum)/aa(i,i)
c        write(*,*)i,dx(i)
      enddo

c Modifying variables

      do i=1,n
        r(i)=r(i)+dx(i)/1.89
      enddo
      ksi1=ksi1+dx(n+1)
      ksi2=ksi2+dx(n+2)

c Output

      gap=.true.
      if(de.gt.gthresh) gap=.false. 
      change=.true.
      if(abs(ei-eiold).gt.ethresh) change=.false. 
      if(abs(ej-ejold).gt.ethresh) change=.false. 
      open(201,file='output',access='append') 
      write(201,1002)main,ei,ej,de*27.2117,gap,change
      close(201)

      if(change.and.gap) goto 12

1002  format(I6,F18.8,F16.8,F15.8,L10,L11)

c END OF MAIN LOOP

      enddo

      open(201,file='output',access='append') 
      write(201,*)
      write(201,*)"Maximum number of iterations reached"
      write(201,*)
      close(201)

      stop

12    open(201,file='output',access='append') 
      write(201,*)
      write(201,*)"Convergence reached"
      write(201,*)
      close(201)

      stop

      end 
