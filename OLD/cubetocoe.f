      program cubetocoe 
      implicit real*8(a-h,o-z)
      character*2 el
      character*20 junk
      integer atype(800)      
      dimension field(300,300,300) 
      dimension ax(800),ay(800),az(800)
      integer NumAtoms

      read(*,*)
      read(*,*)
      read(*,*)natom,x0,y0,z0
      read(*,*)lenx,akx,temp1,temp2
      read(*,*)leny,temp1,aky,temp2
      read(*,*)lenz,temp1,temp2,akz

      do i=1,natom
        read(*,*)atype(i),temp,ax(i),ay(i),az(i)
      enddo 

      do i=1,lenx
       do j=1,leny
         read(*,*)(field(i,j,k),k=1,lenz)
       enddo 
      enddo  
      elx=0.
      ely=0.
      elz=0.
      sum=0.
      sumal=0.

      do i=1,lenx
       do j=1,leny
        do k=1,lenz
         elx=elx+field(i,j,k)*(x0+(i-1)*akx)
         ely=ely+field(i,j,k)*(y0+(j-1)*aky)
         elz=elz+field(i,j,k)*(z0+(k-1)*akz)
         aax=(x0+(i-1)*akx)
         aay=(y0+(j-1)*aky)
         aaz=(z0+(k-1)*akz)
         al=(aax-ax(1))**2+(aay-ay(1))**2+(aaz-az(1))**2 
         sumal=sumal+field(i,j,k)*al**0.5/1.89
         sum=sum+field(i,j,k)
        enddo 
       enddo 
      enddo 

      elx=elx/sum
      ely=ely/sum
      elz=elz/sum
      sumal=sumal/sum

      sumg=0.

      do i=1,lenx
       do j=1,leny
        do k=1,lenz
         aax=(x0+(i-1)*akx)
         aay=(y0+(j-1)*aky)
         aaz=(z0+(k-1)*akz)
         al=(aax-elx)**2+(aay-ely)**2+(aaz-elz)**2
         sumg=sumg+field(i,j,k)*al
        enddo
       enddo
      enddo


      sumg=sumg/sum/1.89**2
      sumg=sumg**0.5

c      write(*,*)elx/1.89,ely/1.89,elz/1.89,sum
c      write(*,*)field(80,80,80),lenx,leny,lenz,akx,aky,akz
c      write(*,*)x0+79*akx,x0
c      write(*,*)sumal
      write(*,*)sumg

      do i=1,natom
        al=(elx-ax(i))**2+(ely-ay(i))**2+(elz-az(i))**2 
        write(*,2)i,atype(i),al**0.5/1.89,ax(i)/1.89
     &  ,ay(i)/1.89,az(i)/1.89
      enddo 
2     format(2I4,4F18.12)
      stop
      end
