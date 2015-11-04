      program WriteGeometry
      implicit real*8(a-h,o-z)
      character*2 el
      character*20 junk
      integer NumAtoms

      i=0
      read(*,*)NumAtoms,NumModes
10    read(*,*) junk
      if (junk.eq.'FREQUENCIES    ') i=i+1
      if (i.eq.2) goto 20
      goto 10

20    continue

      read(*,*) 
      read(*,*) 
      read(*,*) junk
      read(*,*) 
      read(*,*) junk
      read(*,*) 

      write(*,*)'UNITS=BOHR'
      write(*,1003)NumAtoms
 1003 format(i2)

      do i=1,NumAtoms
         read(*,*)a,el,b,x,y,z
c         if(el.eq.'C')then
c            amu=12.0
c         endif
c         if(el.eq.'O')then
c            amu=16.0
c         endif
c         if(el.eq.'N')then
c            amu=14.0
c         endif
c         if(el.eq.'H')then
c            amu=1.0
c         endif
         write(*,1004)el,x,y,z
       enddo
         
 1004 format(A10,3f20.10)       

       stop
       end
