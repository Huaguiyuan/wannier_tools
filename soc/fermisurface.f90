! calculate bulk's energy band using wannier TB method
  subroutine fermisurface3D

     use mpi
     use para

     implicit none

     integer :: ik, i, j, l
	  integer :: knv3
     integer :: nkx
     integer :: nky
     integer :: nkz

     integer :: bxsf_unit

     integer :: ierr
     real(dp) :: kz
     real(Dp) :: k(3)
     
     ! Hamiltonian of bulk system
     complex(Dp) :: Hamk_bulk(Num_wann,Num_wann) 

     real(dp) :: kxmin, kxmax, kymin, kymax, kzmin, kzmax

     real(dp), allocatable :: kxyz(:,:)
     real(dp), allocatable :: W(:)
     real(dp), allocatable :: eigval(:,:)
     real(dp), allocatable :: eigval_mpi(:,:)

     nkx= Nk
     nky= Nk
     nkz= Nk
     allocate( kxyz(3, nkx*nky*nkz))
     kxyz=0d0

     kxmin= 0.00d0/1d0
     kxmax= 1.00d0/1d0
     kymin= 0.00d0/1d0
     kymax= 1.00d0/1d0
     kzmin= 0.00d0/1d0
     kzmax= 1.00d0/1d0
     kz= 0.0d0
     ik =0
     do i= 1, nkx
        do j= 1, nky
        do l= 1, nkz
           ik =ik +1
           kxyz(1, ik)=kxmin+ (i-1)*(kxmax-kxmin)/dble(nkx-1)
           kxyz(2, ik)=kymin+ (j-1)*(kymax-kymin)/dble(nky-1)
           kxyz(3, ik)=kzmin+ (l-1)*(kzmax-kzmin)/dble(nkz-1)
        enddo
        enddo
     enddo


     knv3= nkx*nky*nkz
     allocate(     W(Num_wann))
     allocate(eigval(Num_wann, knv3))
     allocate(eigval_mpi(Num_wann, knv3))
     eigval_mpi= 0d0
     eigval= 0d0
     do ik= 1+cpuid, knv3, num_cpu
	     if (cpuid==0.and. mod(ik,10000).eq.0) print * , ik

        k(1) = kxyz(1, ik)
        k(2) = kxyz(2, ik)
        k(3) = kxyz(3, ik)

        ! calculation bulk hamiltonian
        Hamk_bulk= 0d0
        call ham_bulk(k, Hamk_bulk)
        call eigensystem_c( 'N', 'U', Num_wann ,Hamk_bulk, W)
        eigval_mpi(:, ik)= W
     enddo

     call mpi_allreduce(eigval_mpi, eigval,size(eigval),&
                       mpi_dp,mpi_sum,mpi_cmw,ierr)

     if (cpuid==0)then
        bxsf_unit= 101
        open(bxsf_unit,FILE='wannier90.bxsf',STATUS='UNKNOWN',FORM='FORMATTED')
        write(bxsf_unit,*) ' BEGIN_INFO'
        write(bxsf_unit,*) '      #'
        write(bxsf_unit,*) '      # this is a Band-XCRYSDEN-Structure-File'
        write(bxsf_unit,*) '      # for Fermi Surface Visualisation'
        write(bxsf_unit,*) '      #'
        write(bxsf_unit,*) '      # Generated by the Wannier90 code http://www.wannier.org'
        write(bxsf_unit,*) '      #'
        write(bxsf_unit,*) ' END_INFO'
        write(bxsf_unit,*) 
        write(bxsf_unit,*) ' BEGIN_BLOCK_BANDGRID_3D'
        write(bxsf_unit,*) 'from_wannier_code'
        write(bxsf_unit,*) ' BEGIN_BANDGRID_3D_fermi'
        write(bxsf_unit,*) num_wann
        write(bxsf_unit,*) nkx, nky, nkz
        write(bxsf_unit,*) '0.0 0.0 0.0'
        write(bxsf_unit,*) (Kua(i), i=1,3)
        write(bxsf_unit,*) (Kub(i), i=1,3)
        write(bxsf_unit,*) (Kuc(i), i=1,3)
        do i=1,num_wann
           write(bxsf_unit,*) 'BAND: ',i
           do ik=1, knv3
              write(bxsf_unit,'(2E16.8)') eigval(i, ik)
           enddo
        enddo
        write(bxsf_unit,*) 'END_BANDGRID_3D'
        write(bxsf_unit,*) ' END_BLOCK_BANDGRID_3D'
        close(bxsf_unit)
    
     endif

   return
   end subroutine fermisurface3D



! calculate bulk's energy band using wannier TB method
  subroutine fermisurface

     use mpi
     use para

     implicit none

     integer :: ik, i, j
	  integer :: knv3
     integer :: nkx
     integer :: nky

     integer :: ierr
     real(dp) :: kz
     real(Dp) :: k(3)
     
     ! Hamiltonian of bulk system
     complex(Dp) :: Hamk_bulk(Num_wann,Num_wann) 

     real(dp) :: kxmin, kxmax, kymin, kymax
     real(dp) :: zmin, zmax
     real(dp) :: kxmin_shape, kxmax_shape, kymin_shape, kymax_shape

     real(dp), allocatable :: kxy(:,:)
     real(dp), allocatable :: kxy_shape(:,:)
     
     real(dp), allocatable :: dos(:)
     real(dp), allocatable :: dos_mpi(:)

     complex(dp), allocatable :: ones(:,:)

     nkx= Nk
     nky= Nk
     allocate( kxy(2, nkx*nky))
     allocate( kxy_shape(2, nkx*nky))
     kxy=0d0
     kxy_shape=0d0

     kxmin= 0.10d0/1d0
     kxmax= 0.30d0/1d0
     kymin=-0.05d0/1d0
     kymax= 0.05d0/1d0
     kz= 0.0d0
     ik =0
     do i= 1, nkx
        do j= 1, nky
           ik =ik +1
           kxy(1, ik)=kxmin+ (i-1)*(kxmax-kxmin)/dble(nkx-1)
           kxy(2, ik)=kymin+ (j-1)*(kymax-kymin)/dble(nky-1)
           kxy_shape(1, ik)= kxy(1, ik)* Kua(1)+ kxy(2, ik)* Kub(1)
           kxy_shape(2, ik)= kxy(1, ik)* Kua(2)+ kxy(2, ik)* Kub(2)
        enddo
     enddo
     kymin_shape=minval(kxy_shape(2,:))
     kymax_shape=maxval(kxy_shape(2,:))
     kxmin_shape=minval(kxy_shape(1,:))
     kxmax_shape=maxval(kxy_shape(1,:))


     knv3= nkx*nky
     allocate( dos    (knv3))
     allocate( dos_mpi(knv3))
     dos    = 0d0
     dos_mpi= 0d0

     allocate(ones(Num_wann, Num_wann))
     ones= 0d0
     do i=1, Num_wann
        ones(i, i)= 1d0
     enddo
     do ik= 1+cpuid, knv3, num_cpu
	     if (cpuid==0) print * , ik

        k(1) = kxy(1, ik)
        k(2) = kxy(2, ik)
        k(3) = kz

        ! calculation bulk hamiltonian
        Hamk_bulk= 0d0
        call ham_bulk(k, Hamk_bulk)

        Hamk_bulk= (E_arc -zi* eta_arc)* ones - Hamk_bulk
        call inv(Num_wann, Hamk_bulk)
        do i=1, Num_wann
           dos(ik)= dos(ik)+ aimag(Hamk_bulk(i, i))/pi
        enddo

     enddo

     call mpi_allreduce(dos,dos_mpi,size(dos),&
                       mpi_dp,mpi_sum,mpi_cmw,ierr)

     if (cpuid==0)then
        open(unit=14, file='fs.dat')
   
        do ik=1, knv3
           write(14, '(3f16.8)')kxy_shape(:, ik), log(dos_mpi(ik))
           if (mod(ik, nky)==0) write(14, *)' '
        enddo
        close(14)
     endif
     zmax= maxval(log(dos_mpi))
     zmin= minval(log(dos_mpi))

     !> minimum and maximum value of energy bands

     !> write script for gnuplot
     if (cpuid==0) then
        open(unit=101, file='fs.gnu')
        write(101, '(a)')'#set terminal  postscript enhanced color'
        write(101, '(a)')"#set output 'fs.eps'"
        write(101, '(3a)')'set terminal  pngcairo truecolor enhanced', &
           ' size 1920, 1680 font ",36"'
        write(101, '(a)')"set output 'fs.png'"
        write(101,'(a, f10.4, 2a, f10.4, a)') &
           'set palette defined ( ', zmin, ' "white", ', &
          '0 "black", ', zmax,'  "red" )'
        write(101, '(a)')'#set palette rgbformulae 33,13,10'
        write(101, '(a)')'unset ztics'
        write(101, '(a)')'unset key'
        write(101, '(a)')'set pm3d'
        write(101, '(a)')'#set view equal xyz'
        write(101, '(a)')'set view map'
        write(101, '(a)')'set border lw 3'
        write(101, '(a)')'#set xtics font ",24"'
        write(101, '(a)')'#set ytics font ",24"'
        write(101, '(a)')'set size ratio -1'
        write(101, '(a)')'unset xtics'
        write(101, '(a)')'unset ytics'
        write(101, '(a)')'set colorbox'
       !write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin, ':', kxmax, ']'
       !write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin, ':', kymax, ']'
        write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin_shape, ':', kxmax_shape, ']'
        write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin_shape, ':', kymax_shape, ']'
        write(101, '(a)')'set pm3d interpolate 2,2'
        write(101, '(2a)')"splot 'fs.dat' u 1:2:3 w pm3d"

     endif


   return
   end subroutine fermisurface

!  calculate bulk's energy band using wannier TB method
   subroutine gapshape3D

      use mpi
      use para
      
      implicit none
      
      integer :: ik, i, j, l
	   integer :: knv3
      integer :: nkx
      integer :: nky
      integer :: nkz
      
      integer :: ierr, i1, i2
      real(dp) :: kz
      real(Dp) :: k(3)
      real(Dp) :: k1
      real(Dp) :: k2
      real(Dp) :: k3
      real(Dp) :: k11(3), k12(3)
      real(Dp) :: k21(3), k22(3)
      real(Dp) :: k31(3), k32(3)
      
      ! Hamiltonian of bulk system
      complex(Dp) :: Hamk_bulk(Num_wann,Num_wann) 
      
      real(dp) :: zmin, zmax
      real(dp) :: kxmin, kxmax, kymin, kymax, kzmin, kzmax
      real(dp) :: kxmin_shape, kxmax_shape, kymin_shape, kymax_shape
      
      real(dp), allocatable :: kxy(:,:)
      real(dp), allocatable :: kxy_shape(:,:)
      
      real(dp), allocatable :: gap(:, :)
      real(dp), allocatable :: gap_mpi(:, :)
      real(dp), allocatable :: W(:)
      
      complex(dp), allocatable :: ones(:,:)
      
      nkx= Nk
      nky= Nk
      nkz= Nk
      allocate( kxy(3, nkx*nky*nkz))
      allocate( kxy_shape(3, nkx*nky*nkz))
      kxy=0d0
      kxy_shape=0d0
      
      kxmin= 0.00d0/1d0
      kxmax= 1.00d0/1d0
      kymin= 0.00d0/1d0
      kymax= 1.00d0/1d0
      kzmin= 0.00d0/1d0
      kzmax= 1.00d0/1d0
      ik =0

      !DFT
     !k11=(/-1.0d0,  0.0d0, -1.0d0/) ! G
     !k12=(/ 1.0d0,  0.0d0,  1.0d0/) ! X
     !k21=(/ 0.0d0,  1.0d0,  1.0d0/) ! G
     !k22=(/ 0.0d0, -1.0d0, -1.0d0/) ! Y
     !k31=(/-1.0d0, -1.0d0,  0.0d0/) ! G
     !k32=(/ 1.0d0,  1.0d0,  0.0d0/) ! Z

      !TB
      k11=(/-1.0d0,  0.0d0, -1.0d0/) ! 
      k12=(/ 1.0d0,  0.0d0,  1.0d0/) ! X
      k21=(/ 0.0d0,  1.0d0,  1.0d0/) ! 
      k22=(/ 0.0d0, -1.0d0, -1.0d0/) ! Y
      k31=(/-1.0d0, -1.0d0,  0.0d0/) ! 
      k32=(/ 1.0d0,  1.0d0,  0.0d0/) ! Z

      do i= 1, nkx
         do j= 1, nky
            do l= 1, nkz
               ik= ik+ 1
              !k1=kxmin+ (i-1)*(kxmax-kxmin)/dble(nkx-1)
              !k2=kymin+ (j-1)*(kymax-kymin)/dble(nky-1)
              !k3=kzmin+ (l-1)*(kzmax-kzmin)/dble(nkz-1)
              !kxy(1, ik)=  (k2+ k3)/1d0
              !kxy(2, ik)=  (k3+ k1)/1d0
              !kxy(3, ik)=  (k1+ k2)/1d0
               kxy(:, ik)= k11+ (k12-k11)*(i-1)/dble(nkx-1)  &
                         + k21+ (k22-k21)*(j-1)/dble(nky-1)  &
                         + k31+ (k32-k31)*(l-1)/dble(nkz-1)
               kxy_shape(:, ik)= kxy(1, ik)* Kua+ kxy(2, ik)* Kub+ kxy(3, ik)* Kuc 
            enddo
         enddo
      enddo

      kxmin_shape=minval(kxy_shape(i1,:))
      kxmax_shape=maxval(kxy_shape(i1,:))
      kymin_shape=minval(kxy_shape(i2,:))
      kymax_shape=maxval(kxy_shape(i2,:))
      
      
      knv3= nkx*nky*nkz
      allocate( gap    (3, knv3))
      allocate( gap_mpi(3, knv3))
      gap    = 0d0
      gap_mpi= 0d0
      
      allocate(W(Num_wann))
      allocate(ones(Num_wann, Num_wann))
      W= 0d0
      ones= 0d0
      do i=1, Num_wann
         ones(i, i)= 1d0
      enddo
      
      if (Numoccupied> Num_wann) then
         stop 'Numoccupied should less than Num_wann'
      endif
      
      do ik= 1+cpuid, knv3, num_cpu
	      if (cpuid==0) print * , ik, knv3
	      if (cpuid==0) write(stdout, *) ik, knv3
      
         k(1) = kxy(1, ik)
         k(2) = kxy(2, ik)
         k(3) = kxy(3, ik)
      
         ! calculation bulk hamiltonian
         Hamk_bulk= 0d0
         call ham_bulk(k, Hamk_bulk)
      
         call eigensystem_c( 'N', 'U', Num_wann ,Hamk_bulk, W)
         gap(1, ik)= W(Numoccupied+1)- W(Numoccupied)
         gap(2, ik)= W(Numoccupied)
         gap(3, ik)= W(Numoccupied+1)
      
      enddo
      
      call mpi_allreduce(gap,gap_mpi,size(gap),&
                        mpi_dp,mpi_sum,mpi_cmw,ierr)
      
      if (cpuid==0)then
         open(unit=15, file='gap3d.dat')
         do ik=1, knv3
            if (abs(gap_mpi(1, ik))< 0.010d0) then
               write(15, '(8f16.8)') kxy_shape(:, ik), (gap_mpi(:, ik))
            endif
         enddo
         close(15)
      endif
      
     !!> minimum and maximum value of energy bands
     !
     !zmax= maxval((gap_mpi))
     !zmin= minval((gap_mpi))
     !
     !!> write script for gnuplot
     !if (cpuid==0) then
     !   open(unit=101, file='gap.gnu')
     !   write(101, '(a)')'#set terminal  postscript enhanced color'
     !   write(101, '(a)')"#set output 'gap.eps'"
     !   write(101, '(3a)')'set terminal  png      truecolor enhanced', &
     !      ' size 1920, 1680 font ",36"'
     !   write(101, '(a)')"set output 'gap.png'"
     !   write(101,'(a, f10.4, 2a, f10.4, a)') &
     !      'set palette defined ( ', zmin, ' "black", ', &
     !      '0.5 "orange", ',zmax,'  "white" )'
     !   write(101, '(a)')'#set palette rgbformulae 33,13,10'
     !   write(101, '(a)')'unset ztics'
     !   write(101, '(a)')'unset key'
     !   write(101, '(a)')'set pm3d'
     !   write(101, '(a)')'#set view equal xyz'
     !   write(101, '(a)')'set view map'
     !   write(101, '(a)')'set border lw 3'
     !   write(101, '(a)')'#set xtics font ",24"'
     !   write(101, '(a)')'#set ytics font ",24"'
     !   write(101, '(a)')'set size ratio -1'
     !   write(101, '(a)')'unset xtics'
     !   write(101, '(a)')'unset ytics'
     !   write(101, '(a)')'set colorbox'
     !   !write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin      , ':', kxmax      , ']'
     !   !write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin      , ':', kymax      , ']'
     !    write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin_shape, ':', kxmax_shape, ']'
     !    write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin_shape, ':', kymax_shape, ']'
     !   write(101, '(a)')'set pm3d interpolate 2,2'
     !   write(101, '(2a)')"splot 'gap.dat' u 1:2:3 w pm3d"
     !
     !endif
      
      
      return
   end subroutine gapshape3D


!  calculate bulk's energy band using wannier TB method
   subroutine gapshape

      use mpi
      use para
      
      implicit none
      
      integer :: ik, i, j
	   integer :: knv3
      integer :: nkx
      integer :: nky
      
      integer :: ierr, i1, i2
      real(dp) :: kz
      real(Dp) :: k(3)
      real(Dp) :: k1(3)
      real(Dp) :: k2(3)
      real(Dp) :: k11(3)
      real(Dp) :: k12(3)
      real(Dp) :: k21(3)
      real(Dp) :: k22(3)
      
      ! Hamiltonian of bulk system
      complex(Dp) :: Hamk_bulk(Num_wann,Num_wann) 
      
      real(dp) :: zmin, zmax
      real(dp) :: kxmin, kxmax, kymin, kymax
      real(dp) :: kxmin_shape, kxmax_shape, kymin_shape, kymax_shape
      
      real(dp), allocatable :: kxy(:,:)
      real(dp), allocatable :: kxy_shape(:,:)
      
      real(dp), allocatable :: gap(:, :)
      real(dp), allocatable :: gap_mpi(:, :)
      real(dp), allocatable :: W(:)
      
      complex(dp), allocatable :: ones(:,:)
      
      nkx= Nk
      nky= Nk
      allocate( kxy(3, nkx*nky))
      allocate( kxy_shape(3, nkx*nky))
      kxy=0d0
      kxy_shape=0d0
      
      kxmin=-1.00d0/1d0
      kxmax= 1.00d0/1d0
      kymin=-1.00d0/1d0
      kymax= 1.00d0/1d0
      kz= 0.0d0
      ik =0
     
      !> kx-ky plane
     !k11=(/ 0.5000d0, 0d0, 0.0d0/) !  
     !k12=(/ 0.8000d0, 0d0, 0.0d0/) ! X
     !k21=(/ 0.0d0, 0.500d0,0.0d0/) !            
     !k22=(/ 0.0d0, 0.800d0,0.0d0/) ! Y

      !> for space group 43 model
      !> ky-kz plane
      k11=(/ 0.0d0, 1d0,1.0d0/) !  
      k12=(/ 0.0d0,-1.0d0,-1.0d0/) ! y
      k21=(/-1.0d0,-1.0d0,0.0d0/) ! 
      k22=(/ 1.0d0, 1.0d0,0.0d0/) ! z

      !> kx-kz plane
     !k11=(/0.0d0, 0d0, 0.0d0/) ! Y
     !k12=(/0.0d0, 1d0, 1.0d0/) ! Y
     !k21=(/ 0.0d0, 0.0d0,0.0d0/) !
     !k22=(/ 1.0d0, 1.0d0,0.0d0/) ! Z

      !> kx-kz plane ky= -0.5
     !k11=(/ 0.0d0, 0.0d0, 0.0d0/) ! Y
     !k12=(/-0.5d0, 1.0d0, 0.5d0/) ! Y
     !k21=(/ 0.0d0, 0.0d0, 0.0d0/) !
     !k22=(/ 0.5d0, 1.0d0,-0.5d0/) ! Z

      !> kx-ky  space group 43
      !k1=(/0.0d0,0.5d0,0.5d0/)
      !k2=(/0.5d0,0d0,0.5d0/)
      !k11=(/0.0d0,0d0,0.0d0/) ! G
      !k12=(/0.0d0,1d0,1.0d0/) ! Y
      !k21=(/ 0.0d0, 0.0d0, 0.0d0/) ! X 
      !k22=(/ 1.0d0, 0.0d0, 1.0d0/) ! X

      !> for space group 43 DFT
      !> ky-kz plane
     !k11=(/ 1.0d0, 0d0,   1.0d0/) !  
     !k12=(/-1.0d0, 0.0d0,-1.0d0/) ! y
     !k21=(/-1.0d0,-1.0d0,0.0d0/) ! 
     !k22=(/ 1.0d0, 1.0d0,0.0d0/) ! z


      i1=2
      i2=3
      do i= 1, nkx
         do j= 1, nky
            ik =ik +1
            !kxy(1, ik)=kxmin+ (i-1)*(kxmax-kxmin)/dble(nkx-1)
            !kxy(2, ik)=kymin+ (j-1)*(kymax-kymin)/dble(nky-1)
            kxy(:, ik)= k11+(k12-k11)*(i-1)/dble(nkx-1)+  k21+ (k22-k21)*(j-1)/dble(nky-1)
            kxy_shape(:, ik)= kxy(1, ik)* Kua+ kxy(2, ik)* Kub+ kxy(3, ik)* Kuc 
         enddo
      enddo

      kymin_shape=minval(kxy_shape(i2,:))
      kymax_shape=maxval(kxy_shape(i2,:))
      kxmin_shape=minval(kxy_shape(i1,:))
      kxmax_shape=maxval(kxy_shape(i1,:))
      
      
      knv3= nkx*nky
      allocate( gap    (3, knv3))
      allocate( gap_mpi(3, knv3))
      gap    = 0d0
      gap_mpi= 0d0
      
      allocate(W(Num_wann))
      allocate(ones(Num_wann, Num_wann))
      W= 0d0
      ones= 0d0
      do i=1, Num_wann
         ones(i, i)= 1d0
      enddo
      
      if (Numoccupied> Num_wann) then
         stop 'Numoccupied should less than Num_wann'
      endif
      
      do ik= 1+cpuid, knv3, num_cpu
	      if (cpuid==0) print * , ik, knv3
	      if (cpuid==0)write(stdout, *) ik, knv3
      
         k(1) = kxy(1, ik)
         k(2) = kxy(2, ik)
         k(3) = kxy(3, ik)
      
         ! calculation bulk hamiltonian
         Hamk_bulk= 0d0
         call ham_bulk(k, Hamk_bulk)
      
         call eigensystem_c( 'N', 'U', Num_wann ,Hamk_bulk, W)
         gap(1, ik)= W(Numoccupied+1)- W(Numoccupied)
         gap(2, ik)= W(Numoccupied)
         gap(3, ik)= W(Numoccupied+1)
      
      enddo
      
      call mpi_allreduce(gap,gap_mpi,size(gap),&
                        mpi_dp,mpi_sum,mpi_cmw,ierr)
      
      if (cpuid==0)then
         open(unit=14, file='gap.dat')
      
         do ik=1, knv3
           !write(14, '(3f16.8)')kxy      (:, ik), (gap_mpi(ik))
            write(14, '(8f16.8)')kxy_shape (:, ik), log(gap_mpi(1, ik)), &
            gap_mpi(2:3, ik)
            if (mod(ik, nky)==0) write(14, *)' '
         enddo
         close(14)

         open(unit=15, file='gap2d.dat')
         do ik=1, knv3
            if (abs(gap_mpi(1, ik))< 0.10d0) then
               write(15, '(8f16.8)') kxy_shape(:, ik), (gap_mpi(:, ik))
            endif
         enddo
         close(15)
      endif
      
      !> minimum and maximum value of energy bands
      
      zmax= maxval(gap_mpi(1, :))
      zmin= minval(gap_mpi(1, :))
      
      !> write script for gnuplot
      if (cpuid==0) then
         open(unit=101, file='gap.gnu')
         write(101, '(a)')'#set terminal  postscript enhanced color'
         write(101, '(a)')"#set output 'gap.eps'"
         write(101, '(3a)')'set terminal  png      truecolor enhanced', &
            ' size 1920, 1680 font ",36"'
         write(101, '(a)')"set output 'gap.png'"
         write(101,'(a, f10.4, a, f10.4, a, f10.4, a)') &
            'set palette defined ( ', zmin, ' "black", ', &
            (zmin+zmax)/2d0,' "orange", ',zmax,'  "white" )'
         write(101, '(a)')'#set palette rgbformulae 33,13,10'
         write(101, '(a)')'unset ztics'
         write(101, '(a)')'unset key'
         write(101, '(a)')'set pm3d'
         write(101, '(a)')'#set view equal xyz'
         write(101, '(a)')'set view map'
         write(101, '(a)')'set border lw 3'
         write(101, '(a)')'#set xtics font ",24"'
         write(101, '(a)')'#set ytics font ",24"'
         write(101, '(a)')'set size ratio -1'
         write(101, '(a)')'unset xtics'
         write(101, '(a)')'unset ytics'
         write(101, '(a)')'set colorbox'
         !write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin      , ':', kxmax      , ']'
         !write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin      , ':', kymax      , ']'
          write(101, '(a, f10.5, a, f10.5, a)')'set xrange [', kxmin_shape, ':', kxmax_shape, ']'
          write(101, '(a, f10.5, a, f10.5, a)')'set yrange [', kymin_shape, ':', kymax_shape, ']'
         write(101, '(a)')'set pm3d interpolate 2,2'
         write(101, '(2a)')"splot 'gap.dat' u 1:2:3 w pm3d"
      
      endif
      
      
      return
   end subroutine gapshape


   !> get fermilevel for the given hamiltonian
   subroutine get_fermilevel
      use mpi
      use para
      implicit none

      integer :: i1
      integer :: i2
      integer :: i3
      integer :: io
      integer :: ik

      !> number of k points
      integer :: knv3

      integer :: ierr
      integer :: iter
      integer :: itermax

      !> fermi level
      real(dp) :: EF

      real(dp) :: k(3)

      real(dp) ::  Beta 

      real(dp) :: lmin
      real(dp) :: lmax
      real(dp) :: tot


      !> fermi-dirac distribution function
      real(dp), external :: fermi

      !> kpoint coordinates
      real(dp), allocatable :: kpoints(:, :)

      !> eigen value for each kpoint
      real(dp), allocatable :: W(:)
      real(dp), allocatable :: eigvals(:, :)
      real(dp), allocatable :: eigvals_mpi(:, :)

      complex(dp), allocatable :: ham(:, :)

      knv3= Nk*Nk*Nk

      allocate(W(Num_wann))
      allocate(eigvals(Num_wann, knv3))
      allocate(eigvals_mpi(Num_wann, knv3))
      allocate(ham(Num_wann, Num_wann))
      allocate(kpoints(3, knv3))
      eigvals= 0d0
      eigvals_mpi= 0d0
      ham= 0d0
      kpoints= 0d0
      Beta= 200d0

      ik= 0
      do i1=1, Nk
      do i2=1, Nk
      do i3=1, Nk
         ik= ik+ 1
         kpoints(1, ik)= (i1-1d0)/dble(Nk)
         kpoints(2, ik)= (i2-1d0)/dble(Nk)
         kpoints(3, ik)= (i3-1d0)/dble(Nk)
      enddo
      enddo
      enddo

      do ik=1+ cpuid, knv3, num_cpu
 
         ham= 0d0
         k= kpoints(:, ik)
         call ham_bulk(k, ham)
         call eigensystem_c( 'N', 'U', num_wann, ham, W)
         eigvals_mpi(:, ik)= W
      enddo ! ik

      call mpi_allreduce(eigvals_mpi, eigvals, size(eigvals), &
                         mpi_dp, mpi_sum, mpi_cmw, ierr)

      ! using bisection algorithm to search the fermi level
      iter= 0 
      itermax= 100
      tot= 9999d0
      lmin= minval(eigvals)
      lmax= maxval(eigvals)
      if (cpuid==0) print *, 'Emin= ', lmin
      if (cpuid==0) print *, 'Emax= ', lmax
      do while( abs(tot- Ntotch).gt. eps6 .and. iter.lt.itermax)

         iter= iter+ 1

         EF= (lmin+ lmax)* half

         tot= 0d0
         do ik=1, knv3
            do io=1, Num_wann
               tot= tot+ fermi(eigvals(io, ik)- EF, Beta)
            enddo ! io
         enddo ! ik
         tot= tot/dble(knv3)

         if (tot > Ntotch)then
            lmax= EF
         else
            lmin= EF
         endif

         if (cpuid==0) then
             write(*, 100)iter, tot-Ntotch, EF, '  Charge: ', tot
         endif
      100   format(2x,">iter",i4,2x,"diff:",f12.6,2x,"EF: ",f12.6,a,f12.6)

      enddo ! bisection

      E_fermi= EF

      return
   end subroutine get_fermilevel

   !------------+------------+------------+------------+------------+--------+!
   ! calculate the Fermi-Dirac distribution
   !------------+------------+------------+------------+------------+--------+!
   function fermi(omega, Beta) result(value)

      use para
      implicit none

      ! >> inout variables
      real(dp), intent(in) :: omega
      real(dp), intent(in) :: Beta

      ! return value
      real(dp) :: value
    
      ! avoid numerical instability 
      if (beta*omega .ge. 20d0) then
         value = zero
      elseif (beta*omega.le. -20d0)then
         value = one
      else
         value= one/(one+exp(beta*omega))
      endif

      return
   end function fermi



