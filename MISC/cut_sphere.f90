!# cut_sphere           D. Hollas, 2014
!- Program for cutting solvent molecules around the solute
!  from an xyz file.

!- It assumes that the solute atoms are the first atoms in the file.
!- The coordinates are read from standard input.
!- See help in subroutine PrintHelp().

!  There are two modes of action:
!  i) Pick closest nmol solvent molecules.
!  ii) Pick all solvent molecules within specified radius. 

!- There are 3 ways how to determine the distance of solvent to solute.
!  1. Closest distance between ANY solvent atom and ANY solute atom.
!     This is the default if we want specific number of solvent molecules.
!  2. Distance is determined relative to the geometrical center of the solute.
!     This is the default if we cut specific radius. (option -com)
!  3. Distance is determined relative to one specific atom of the solute.
!     (option -i idx)

program cut_sphere
   implicit none
   integer, parameter :: MAXATOM=10000
   character(len=2)   :: at(maxatom),at_temp(MAXATOM)
   real*8    :: x(maxatom), y(maxatom), z(maxatom)
   real*8    :: x_temp(maxatom), y_temp(maxatom), z_temp(maxatom)
   real*8    :: rmin(maxatom),r(maxatom,maxatom), rmolmin(maxatom)
   integer   :: index(maxatom),index_rev(maxatom)
   integer   :: natmol=3, nmol=-1, nsolute=-1, atidx=-1
   integer   :: nmoltotal, natom
   real*8    :: rad=-1
   logical   :: lcom=.false., ltrans=.false., lref=.false.
   integer   :: i, j, iat, imol, idx
   real*8    :: xt, yt, zt, get_distance, box(3)
   character(len=100) :: chjunk, chref

   box(1)=-1; box(2)=-1; box(3)=-1;


   call Get_cmdline(natmol, nmol, nsolute, rad, lcom, atidx, ltrans, lref, chref, box)

   read(*,*)natom
   if(natom.gt.maxatom)then
      write(*,*)'ERROR: number of atoms is greater than maximum.'
      write(*,*)'Adjust parameter MAXATOM and recompile'
      stop 1
   end if

   read(*,*)
   do i=1,natom
      read(*,*)at(i),x(i),y(i),z(i)
   enddo

   ! When using reference geometry (e.g. if we are "cutting" velocities)
   if(lref)then
      at_temp=at
      x_temp=x
      y_temp=y
      z_temp=z
      open(500, file=chref,access="sequential",action="read")
      read(500,*)i
      if(i.ne.natom)then
         write(*,*)"ERROR: Number of atoms in reference and input files do not match!"
         stop 1
      end if

      read(500,*)
      do i=1,natom
         read(500,*)at(i),x(i),y(i),z(i)
         if(at(i).ne.at_temp(i))then
            write(*,*)"ERROR: Incompatible atom types!",at(i),at_temp(i),"Line:",i
            stop 1
         end if
      enddo

   end if

   if (lcom.or.ltrans)then
      xt=0.0
      yt=0.0
      zt=0.0
      do i=1,nsolute
         xt=xt+x(i)
         yt=yt+y(i)
         zt=zt+z(i)
      enddo
      xt=xt/nsolute
      yt=yt/nsolute
      zt=zt/nsolute
      write(*,*)'Coordinates of the geometrical center of the solute.'
      write(*,*)xt, yt, zt
   end if

   if(atidx.gt.0)then
      xt=x(atidx)
      yt=y(atidx)
      zt=z(atidx)
      write(*,*)'Coordinates of the atom around which we cut:'
      write(*,*)xt, yt, zt
   end if

   if (ltrans.or.box(1).gt.0)then
      write(*,*)'Origin of coordinates will be a:'
      write(*,*)xt, yt, zt
      write(*,*)'Translating the molecule to the origin.'
      do iat=1,natom
         x(iat)=x(iat)-xt
         y(iat)=y(iat)-yt
         z(iat)=z(iat)-zt
      end do
      xt=0.0d0; yt=0.0d0; zt=0.0d0
   end if

 

!  Determine the closest distance of every solvent atoms to solute
!  based on all atoms in the solute
   if(.not.lcom.and.atidx.lt.0)then
      do i=nsolute+1,natom
         rmin(i)=100000d0
         do j=1,nsolute
            r(i,j) = get_distance(x(j), y(j), z(j), x(i), y(i), z(i), box)
!            r(i,j)=(x(i)-x(j))**2+(y(i)-y(j))**2+(z(i)-z(j))**2 
!            r(i,j)=dsqrt(r(i,j))
            if(r(i,j).lt.rmin(i))then
               rmin(i)=r(i,j)
            endif
         enddo
      enddo
   end if
    
!  Determine the distances to the geometrical center
!  or to an atom with index atidx
   if(lcom.or.atidx.gt.0)then
      do i=nsolute+1,natom
         rmin(i) = get_distance(xt, yt, zt, x(i), y(i), z(i), box)
      enddo
   end if

!  total number of solvent molecules
   nmoltotal=(natom-nsolute)/natmol

!  Now we have to determine, which atom in each molecule is closest
!  i.e. determine the distance of each solvent molecule from solute
   do imol=1,nmoltotal
      rmolmin(imol)=10000d0
      idx=nsolute+1+(imol-1)*natmol
      do iat=idx,idx+natmol-1
         if(rmin(iat).lt.rmolmin(imol))then
            rmolmin(imol)=rmin(iat)
         endif
      enddo
   enddo
   
! determine, how many molecules are in the radius
   if (rad.gt.0)then
      nmol=0
      do imol=1,nmoltotal
         if(rmolmin(imol).lt.rad)then
            nmol=nmol+1
         end if
      end do
      write(*,*)'Number of solvent molecules within radius ',rad
      write(*,*)'is', nmol
   end if

! Center the solvent molecules around solute if PBC
  if(box(1).gt.0) call solvent2box(x, y, z, box, nsolute, nmoltotal, natmol, MAXATOM)
     

! Here's where the index ordering happens.
! ###############################################
   do i=1,nmoltotal
      index(i)=1
      do j=1,nmoltotal

         if(i.eq.j) cycle

!        now we have to determine, which molecule is closer
         if(rmolmin(i).gt.rmolmin(j))then
          index(i)=index(i)+1
         endif

      enddo
      index_rev(index(i))=i
   enddo

!  Move input coordinates back in place 
!  instead of reference geometry
   if(lref)then
      x=x_temp
      y=y_temp
      z=z_temp
   end if
       

!  WRITE THE RESULTS----------------------
   open(150,file='cut_qm.xyz')
   write(150,*)natmol*nmol+nsolute
   write(150,*)
   ! first write solute
   do idx=1,nsolute
      write(150,*)at(idx),x(idx),y(idx),z(idx)
   end do
   ! now write ordered solvent molecules
   do imol=1,nmol
      do iat=1,natmol
         idx=nsolute+(index_rev(imol)-1)*natmol+iat
         write(150,*)at(idx),x(idx),y(idx),z(idx)
      enddo
   enddo

   close(150)

!  Now print the solvent that we left out.
   open(150,file='cut_mm.xyz')
   write(150,*)natom-natmol*nmol-nsolute
   write(150,*)
   do imol=nmol+1,nmoltotal
      do iat=1,natmol
         idx=nsolute+(index_rev(imol)-1)*natmol+iat
         write(150,*)at(idx),x(idx),y(idx),z(idx)
      enddo
   enddo

   close(150)

end

subroutine Get_cmdline(natmol, nmol, nsolute, rad, lcom, atidx, ltrans, lref, chref, box)
implicit none
real*8,intent(inout)    :: rad, box(3)
integer, intent(inout)  :: natmol, nmol, nsolute, atidx
logical, intent(inout)  :: lcom, ltrans, lref
character(len=*), intent(out) :: chref
character(len=100)      :: arg
integer                 :: i
real*8                  :: distmax

i=0
do while (i < command_argument_count())
  i=i+1
  call get_command_argument(i, arg)
  
  select case (arg)
  case ('-h', '--help')
    call PrintHelp()
    stop
  case ('-u')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)nsolute
  case ('-v')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)nmol
    if (nmol.le.0)then
       call PrintHelp()
       write(*,*)'ERROR: Number of molecules must be a positive integer.'
       call PrintInputError()
    endif
  case ('-va')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)natmol
  case ('-r')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)rad
    if (rad.le.0)then
       call PrintHelp()
       write(*,*)'ERROR: Radius must be positive.'
       call PrintInputError()
    endif
  case ('-i')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)atidx
    if (atidx.le.0)then
       call PrintHelp()
       write(*,*)'ERROR: Atom index must be positive.'
       call PrintInputError()
    endif
  case ('-com')
    lcom=.true.
  case ('-ref')
    lref=.true.
    i=i+1
    call get_command_argument(i, arg)
    read(arg,'(A)')chref
    write(*,*)'Using reference file '//trim(chref)
  case ('-trans')
    ltrans=.true.
  case ('-box')
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)box(1)
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)box(2)
    i=i+1
    call get_command_argument(i, arg)
    read(arg,*)box(3)
  case default
    call PrintHelp()
    write(*,*)'Invalid command line argument!'
    call PrintInputError()
  end select

end do

! INPUT SANITY CHECK
  if(rad.gt.0.and.nmol.gt.0)then
     write(*,*)'ERROR: Conflicting options -v and -r.'
     write(*,*)'You may cut EITHER constant number of solvent molecules,'
     write(*,*)'OR cut sphere of solvent of fixed radius.'
     call PrintHelp()
     call PrintInputError()
  end if

  if(nmol.lt.0.and.rad.lt.0)then
     call PrintHelp()
     write(*,*)'ERROR: Missing option -v or -r.'
     call PrintInputError()
  end if

  if(nsolute.lt.0)then
     call PrintHelp()
     write(*,*)'ERROR: Number of atoms in solute not specified.'
     call PrintInputError()
  end if

  if(natmol.lt.0)then
     call PrintHelp()
     write(*,*)'ERROR: Number of atoms in a solvent molecule must be positive.'
     call PrintInputError()
  end if

  if(rad.gt.0.and.atidx.le.0)then
     lcom=.true.
  end if

  ! Check size of the box
  if(box(1).gt.0)then
     distmax=100000
     do i=1,3
        if(box(i).lt.distmax) distmax = box(i)
     end do
     distmax = distmax / 2.0d0

     if(.not.lcom.and.atidx.le.0)then
        write(*,*)'ERROR: PBC not supported with this setting.'
        write(*,*)'Please set -com or -i options.'
        stop 1
     end if
  end if

  if(rad.gt.0.and.box(1).gt.0)then
     if(rad.gt.distmax)then
        write(*,*)'Error: Radius is bigger that half size of the box!'
     end if
  end if

end subroutine Get_cmdline

real*8 function get_distance(x1, y1, z1, x2, y2, z2, box)
   implicit none
   real*8,intent(in)  :: x1, y1, z1
   real*8,intent(inout)  :: x2, y2, z2
   real*8,intent(in)  :: box(3)
!   real*8,optional,intent(in)  :: box(3)
   real*8  :: dx, dy, dz, temp

   dx = x1 - x2
   dy = y1 - y2
   dz = z1 - z2

!   if (present(box))then
     if (box(1).gt.0)then
        dx = dx - box(1) * nint(dx/box(1))
        dy = dy - box(2) * nint(dy/box(2))
        dz = dz - box(3) * nint(dz/box(3))
      end if
!   end if
   
   temp = dx*dx + dy*dy + dz*dz
   temp = dsqrt(temp)
   get_distance = temp
   return 

end function

! WARNING: this code works only if -com or -i are set 
! We expect that the molecules have been translated to the center of origin
subroutine solvent2box(x, y, z, box, nsolute, nmoltotal, natmol,maxatom)
implicit none
real*8,intent(inout) :: x(maxatom), y(maxatom), z(maxatom)
real*8,intent(in)    :: box(3)
integer,intent(in)   :: nsolute, nmoltotal, natmol, maxatom
real*8   :: dx, dy, dz, temp
integer  :: imol, iat, idx
real*8   :: shiftx, shifty, shiftz, pom
real*8, parameter    :: epsilon=0.000001d0


do imol=1, nmoltotal

   shiftx=0.0d0 ; shifty=0.0d0 ; shiftz=0.0d0
!  First determine, whether we shift in given direction
   do iat=1,natmol
      idx = nsolute + (imol-1)*natmol+iat
      pom = nint(x(idx)/box(1)) * box(1)
      if(abs(pom).gt.abs(shiftx)) shiftx = pom
      pom = nint(y(idx)/box(2)) * box(2)
      if(abs(pom).gt.abs(shifty)) shifty = pom
      pom = nint(z(idx)/box(3)) * box(3)
      if(abs(pom).gt.abs(shiftz)) shiftz = pom
   end do

!  Shift solvent molecules as a whole!!
   if(abs(shiftx).gt.epsilon)then
     do iat=1,natmol
         idx = nsolute + (imol-1)*natmol+iat
         x(idx) = x(idx) - shiftx
     end do
   end if
   if(abs(shifty).gt.epsilon)then
     do iat=1,natmol
         idx = nsolute + (imol-1)*natmol+iat
         y(idx) = y(idx) - shifty
     end do
   end if
   if(abs(shiftz).gt.epsilon)then
     do iat=1,natmol
         idx = nsolute + (imol-1)*natmol+iat
         z(idx) = z(idx) - shiftz
     end do
   end if

end do

end subroutine

subroutine PrintHelp()
implicit none
    print '(a)', ''
    print '(a)', 'Program for cutting solvent molecules around a given solute from a larger solvated system.'
    print '(a)', 'You may cut either specific number of closest solvent molecules'
    print '(a)', 'or all solvent mocules within given radius.'
    print '(a)', ''
    print '(a)', 'There are 3 ways how to determine the distance of solvent to solute.'
    print '(a)', '  1. Closest distance between ANY solvent atom and ANY solute atom.'
    print '(a)', '     This is the default if you want specific number of solvent molecules.'
    print '(a)', '  2. Distance is determined relative to the geometrical center of the solute.'
    print '(a)', '     This is the default if you cut specific radius. (option -com)'
    print '(a)', '  3. Distance is determined relative to one specific atom of the solute.'
    print '(a)', '     (option -i idx)'
    print '(a)', ''
    print '(a)', 'USAGE: ./cut_sphere [OPTIONS] < input.xyz'
    print '(a)', ''
    print '(a)', 'The output geometries are written to files cut_qm.xyz and cut_mm.xyz.'
    print '(a)', ''
    print '(a)', 'cmdline options:'
    print '(a)', ''
    print '(a)', '  -h or --help     Print this information and exit.'
    print '(a)', '  -u  <integer>    Number of atoms in the solute.'
    print '(a)', '  -va <integer>    Number of atoms in one solvent molecule (default=3).'
    print '(a)', '  -v  <integer>    Number solvent molecules to cut.'
    print '(a)', '  -r  <radius>     Radius of the sphere to cut.'
    print '(a)', '  -i  <atidx>      Cut around the atom with index atidx.'
    print '(a)', '  -com             Cut around the geometrical center of molecule.'
    print '(a)', '                   This is the default if -r is specified.'
    print '(a)', '  -trans           Translate the molecule so that the &
                  coordinates of geometrical center are (0, 0, 0).'
    print '(a)', '  -ref <file_name> Use reference geometry to determine atomic distances.'
    print '(a)', '                   Useful when you need to "cut" velocities.'
    print '(a)', '  -box <size_x size_y size_z>  Dimensions of periodic boundary box.'
end subroutine PrintHelp

subroutine PrintInputError()
  write(*,*)'Error during reading input. Exiting...'
  stop 1
end subroutine PrintInputError


