c******************************************************************************************
c p2m1.f : program to calculate P2(t) from simulations and from theory
C ******************************************************************************************
	program inputreader
	integer n,nmol
	open(unit=114,file='protname.txt',status='old')
	read (114,*)
	read(114,*)n
	close(114)
	open(unit=2,file="nmol.dat",status='old')
	read(2,*)nmol
	close(2)
	call p2m1(n,nmol)
	end program inputreader
c*********************************************************
c  catena lineare per una proteina. E' il programma linearp1p2.f
C     CALCULATION OF FILE P2(T),TAU        
	subroutine p2m1(n,nmol)
	implicit double precision(a-h,o-z)
	integer ai1,ai2,ai3,ai4,fintime,k,l,i,j,nmol,nres(nmol),nt,im
	integer,dimension(n,4) :: nlist
	real factor,fricorr(n),eiglam1,eiglam2,eiglam3,avblsq
	DATA P/3.141592654/
	dimension cc(n,n),tc(5000),tt(5000)
        dimension dt(5000),rm(n,3),rnorm(5000),rmodenorm(5000)
	dimension fint0(5000,n),fints0(5000,n),fj0(5000)
	dimension epi0(5000,n),epis0(5000,n),pj0(5000),nbg(n)
	dimension ned(n),mexp(n),difm1(n),difp2(n)
        dimension al0(n),avmode(n),itcr(10),tau(n)
	dimension qinvm(n,n),qm(n,n),eigmu(n),eiglam(n),dot(n,n)
	character(32)protname,ii,cnmol,ctitle,ctau
	character(128)cplot

c
!        Open(unit=63,file='tau',status='unknown')
!	open(unit=67,file='taum1',status='unknown')
!	open(unit=65,file='p2',status='unknown')
c	open(unit=66,file='m1',status='unknown')
	open(unit=747,file='sigma',status='old')
	open(unit=789,file='length',status='old')
!	open(unit=790, file='rotamp.dat')
!	open(unit=791, file='intamp.dat')
	open(unit=114,file='protname.txt',status='old')
	read(114,*)protname
	close(114)
	protname=adjustl(protname)
	read(747,*) 
	read(747,*) sg ! sigma
	close(747)

c ***************************************************
c ************now the calculation from the theory****
c****************************************************
	fricorr=0.0
	Rb=.00198 !(boltzmanns constant in kcal/mol*K)
	open(unit=114,file='temp',status='old')
	read(114,*)T
	close(114)
	open(unit=114,file='avblsq',status='old')
	read(114,*)avblsq
	close(114)
	open(unit=10,file='fmad_mp_60.dat',status='old')
	do i=1,n-nmol
	read(10,*)fricorr(i)
	fricorr(i)=exp(fricorr(i)/(Rb*T))
	end do

	qinvm=0.0
	qm=0.0
	eigmu=0.0
	eiglam=0.0
	dot=0.0
	nm1=n-nmol
	cc=0.0
	rnorm=0.0
	rmodenorm=0.0
	eiglam1=0.0
	eiglam2=0.0
	eiglam3=0.0
	open(unit=99,file="lambda_eig",status='old') !read in all values
	do i=1,nm1
	read(99,*)eiglam(i)
c	write(*,*)eiglam(i)
	end do
	close(99)
	open(unit=99,file="QINVmatrix",status='old')
	do i=1,nm1
	do j=1,nm1
	read(99,*)qinvm(i,j)
c	write(*,*)qinvm(i,j)
	end do
	end do
	close(99)
	open(unit=99,file="Qmatrix",status='old')
	do i=1,nm1
	do j=1,nm1
	read(99,*)qm(i,j)
c	write(*,*)qm(i,j)
	end do
	end do
	close(99)
	open(unit=99,file="mu_eig",status='old')
	do i=1,nm1
	read(99,*)eigmu(i)
c	write(*,*)eigmu(i)
	end do
	close(99)
	nres=0
	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)
	open(unit=2,file="nres"//trim(cnmol)//".dat",status='old')
	read(2,*)nres(i)
	close(2)
!	write(*,*)nres(i)
	end do
!	open(unit=13,file=trim(protname)//'_ldot.av',status='old')
!	do i=1,nm1
!	do j=1,nm1
!	read(13,*)dot(i,j)
c	write(*,*)dot(i,j)
!	end do
!	end do
!	close(13)

	tau=0.0 ! mode timescale in ps
	do i=1,nm1
	tau(i)=fricorr(i)/(sg*eiglam(i))
	end do

	open(unit=111,file='stackplot')
	do i=4,nm1
	nt=nres(1)
	im=1
	write(ii,*)i
	ii=adjustl(ii)
	ctitle='mstack_'//trim(ii)
	write(*,*)ctitle
	open(unit=110,file=trim(ctitle))
	write(110,*)'0.0'
	write(110,*)'0.0'
	do j=1,nm1
	if(j.eq.nt)then
	nt=nt+nres(i)
	im=im+1
	write(110,*)'0.0'
	end if
	write(110,*)(((avblsq*qm(j,i)**2)/eigmu(i))**.5)*10 !mode fluclength in ang
	end do
	close(110)
	write(ctau,*)tau(i)
	ctau=adjustl(ctau)
	cplot=' "'//trim(ctitle)//
     &'" using 1 notitle lt palette cb '//trim(ctau)//',\'
	write(*,'(A)')trim(cplot)
	write(111,'(A)')trim(cplot)
	end do
	close(111)

	end
