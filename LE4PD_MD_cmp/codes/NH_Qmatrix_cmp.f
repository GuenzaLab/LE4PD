	program inputreader
	integer nfrs,n,nmol
	open(unit=5,file="protname.txt",status='old')
	read(5,*)
	read(5,*)n
	read(5,*)nfrs
	close(5)
	open(unit=2,file="nmol.dat",status='old')
	read(2,*)nmol
	close(2)
!	n=2*n
	write(*,*)n,nfrs
!	nfrs=500 !testing!
	call umatrix(n,nmol,nfrs)
	End program inputreader

	subroutine umatrix(n,nmol,nfrs)
	integer i,j,k,l,m,imin,jmin,a,nca,n,nfrs,nmol,nres(nmol),nt
	real, dimension(n) :: rxn,ryn,rzn,lavmsqnh,avlxnh,avlynh,avlznh
	real, dimension(n) :: avlmagnh,rxh,ryh,rzh,lxNH,lyNH,lzNH,lmagNH
	real, dimension(n) :: avlxca,avlyca,avlzca,avlmagca
	real, dimension(n) :: rxca,ryca,rzca,lavmca
	real, dimension(n) :: lxca,lyca,lzca,lmagca
	real,dimension(n) :: s1NH,avximsq,NHorder
	real,dimension(3,3) :: RM
	real,dimension(3,1) :: vc1,vc2,vdip1,vdip2
	real rnx,rny,rnz,dipl,rnl,theta,thetadot,dot,cross,rlx,rly,rlz
	real lcadot1,lcadot2,avblnhsq
	real, dimension(n,n) :: qinvm,qm,Aia,AiaCA,QmatrixNH
	real, dimension(n,nfrs) :: lixnh,liynh,liznh,limagnh
     &,dlnhx,dlnhy,dlnhz,dlnhmag
	real, dimension(n,nfrs) :: lixca,liyca,lizca,limagca,
     &rlixca,rliyca,rlizca,xix,xiy,xiz,xim
	real, dimension(n,0:nfrs) :: dipcorr,dipcorr2,dipcorr3
	character(32)protname,cnmol
	character(16)aa,ii
	write(*,*)"no. of ca:",n
	lixnh=0.0
	liynh=0.0
	liznh=0.0
	limag=0.0
	lixca=0.0
	liyca=0.0
	lizca=0.0
	limagca=0.0
	xix=0.0
	xiy=0.0
	xiz=0.0
	xim=0.0
	qinvm=0.0
	qm=0.0
	dipcorr=0.0
	Aia=0.0
	AiaCA=0.0
	QmatrixNH=0.0
	open(unit=21,file='QINVmatrix',status='old')
	do i=1,n-nmol
	do j=1,n-nmol
	read(21,*)qinvm(i,j)
	end do
	end do
	close(21)
	open(unit=5,file="protname.txt",status='old')
	read(5,'(A)')protname
	close(5)
	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)	
	open(unit=2,file="nres"//trim(cnmol)//".dat",status='old')
	read(2,*)nres(i)
	close(2)
	end do
	protname=adjustl(protname)
	rxn=0.0
	ryn=0.0
	rzn=0.0
	rxh=0.0
	ryh=0.0
	rzh=0.0
	rxca=0.0
	ryca=0.0
	rzca=0.0
	lxnh=0.0
	lynh=0.0
	lznh=0.0
	lxca=0.0
	lyca=0.0
	lzca=0.0
	lmag=0.0
	lmagca=0.0
	lavm=0.0
	s1NH=0.0
	rnx=0.0
	rny=0.0
	rnz=0.0
	rnl=0.0
	RM=0.0
	vcc=0.0
	vdip=0.0
	avrnhin3=0.0
	thetadot=0.0
	avlx=0.0
	avly=0.0
	avlz=0.0
	avlmag=0.0
	avlxca=0.0
	avlyca=0.0
	avlzca=0.0
	avlmagca=0.0
	dlnhx=0.0
	dlnhy=0.0
	dlnhz=0.0
	dlnhmag=0.0
	lavmsq=0.0
	rlixca=0.0
	rliyca=0.0
	rlizca=0.0
	avximsq=0.0
	!read from trajectory
	open(unit=11,file='nitro.g96',status='old')
	open(unit=12,file='hydro.g96',status='old')
	open(unit=13,file=trim(protname)//'.g96',status='old')
	!skip first 7,now read and calculate stuff
	do i=1,7
	read(11,*)
	read(12,*)
	read(13,*)
	end do

	do k=1,nfrs
	rxn=0.0
	ryn=0.0
	rzn=0.0
	rxh=0.0
	ryh=0.0
	rzh=0.0
	rxca=0.0
	ryca=0.0
	rzca=0.0
	lxnh=0.0
	lynh=0.0
	lznh=0.0
	lxca=0.0
	lyca=0.0
	lzca=0.0
	lmag=0.0
	lmagca=0.0
	if(mod(k,10000).eq.0)write(*,*)"reading frame",k
	do j=1,n
	read(11,*)rxn(j),ryn(j),rzn(j)
	read(12,*)rxh(j),ryh(j),rzh(j)
	end do

	do j=1,n !ca
	read(13,*)rxca(j),ryca(j),rzca(j)
	end do
	j=1
	i=1 !mol number
	nt=nres(1)
	do l=1,n-1
!	if(l.eq.10)write(*,*)j,k
	lxnh(j)=rxh(l)-rxn(l)
	lynh(j)=ryh(l)-ryn(l)
	lznh(j)=rzh(l)-rzn(l)
	lmagnh(j)=(lxnh(j)**2+lynh(j)**2+lznh(j)**2)**.5
	lavmsqnh(j)=lavmsqnh(j)+lmagnh(j)**2
	lxca(j)=rxca(l+1)-rxca(l)
	lyca(j)=ryca(l+1)-ryca(l)
	lzca(j)=rzca(l+1)-rzca(l)
	lmagca(j)=(lxca(j)**2+lyca(j)**2+lzca(j)**2)**.5
c	write(*,*)"ca:",lmagca(j)
	if(k.eq.nt)then !drop bonds between molecules
!	write(*,*)nt
	lavmsqnh(j)=lavmsqnh(j)-lmagnh(j)**2
	j=j-1
	i=i+1
	nt=nt+nres(i)
	end if
	j=j+1
	end do

	!skip 8 lines
	do j=1,8
	read(11,*)
	read(12,*)
	read(13,*)
	end do

!	put into array
	do j=1,n-nmol !bond loop
	lixnh(j,k)=lxnh(j)
	liynh(j,k)=lynh(j)
	liznh(j,k)=lznh(j)
	limagnh(j,k)=lmagnh(j)
	end do
	do j=1,n-nmol !ca
	lixca(j,k)=lxca(j)
	liyca(j,k)=lyca(j)
	lizca(j,k)=lzca(j)
	limagca(j,k)=lmagca(j)
	end do

!	calculating instantaneous mode vector
	do a=1,n-nmol !mode loop
	do j=1,n-nmol !residue loop
	xix(a,k)=qinvm(a,j)*lxca(j)+xix(a,k)
	xiy(a,k)=qinvm(a,j)*lyca(j)+xiy(a,k)
	xiz(a,k)=qinvm(a,j)*lzca(j)+xiz(a,k)
	xim(a,k)=((xix(a,k)**2+xiy(a,k)**2+xiz(a,k)**2)**.5)
	end do
!	xix(a,k)=xix(a,k)/(xim(a,k)) !unit vector needed
!	xiy(a,k)=xiy(a,k)/(xim(a,k))
!	xiz(a,k)=xiz(a,k)/(xim(a,k))
c	write(*,*)"norm mode:",((xix(a,k)**2+xiy(a,k)**2+xiz(a,k)**2)**.5)
	avximsq(a)=avximsq(a)+xim(a,k)**2
	end do

	!come out of time loop
	end do
	close(11)
	close(12)
	close(13)

	!normalize
	do i=1,n-nmol
	lavmsqnh(i)=lavmsqnh(i)/real(nfrs) 
	write(*,*)lavmsqnh(i)
	end do

	do j=1,n-nmol !ca
	avlxca(j)=avlxca(j)/real(nfrs)
	avlyca(j)=avlyca(j)/real(nfrs)
	avlzca(j)=avlzca(j)/real(nfrs) 
	avlmagca(j)=(avlxca(j)**2+avlyca(j)**2+avlzca(j)**2)**.5
c	write(*,*)j,avlmagca(j)
	avximsq(j)=avximsq(j)/real(nfrs)
	end do

	QmatrixNH=0.0
	do i=1,n-nmol
	write(*,*)"bond",l
	write(ii,*)i
	ii=adjustl(ii)
	do k=1,nfrs !time loop

	do a=1,n-nmol !loop over modes to obtain QmatrixNH as <lNH dot xi_a>/<xi_a^2>
	QmatrixNH(i,a)=QmatrixNH(i,a)+((lixnh(i,k))*xix(a,k)+
     &(liynh(i,k))*xiy(a,k)
     &+(liznh(i,k))*xiz(a,k))
	end do !end mode loop
	
	end do !end time loop
	end do !end residue loop

	do i=1,n-nmol !normalize
	do a=1,n-nmol
	QmatrixNH(i,a)=QmatrixNH(i,a)/real(nfrs)
	QmatrixNH(i,a)=QmatrixNH(i,a)/avximsq(a)
	end do
	end do

	open(unit=1,file="Qmatrix_NH")
	do i=1,n-nmol
	do a=1,n-nmol
	write(1,*)QmatrixNH(i,a)
	end do
	end do
	close(1)

	open(unit=1,file="ximsq")
	do i=1,n-nmol
	write(1,*)avximsq(i)
	end do
	close(1)

	open(unit=1,file="avblsqNH")
	open(unit=2,file="blsqNH")
	avblsqNH=0.0
	do i=1,n-nmol
	avblsqNH=avblsqNH+lavmsqnh(i)
	write(2,*)lavmsqnh(i)
	end do
	avblsqNH=avblsqNH/real(n-nmol)
	write(1,*)avblsqNH
	close(1)
	close(2)

	end subroutine

