	program inputreader
	integer nfrs,n
	open(unit=5,file="protname.txt",status='old')
	read(5,*)
	read(5,*)n
	read(5,*)nfrs
	close(5)
	nbins=90
	write(*,*)n,nfrs
	call umatrix(n,nfrs,nbins)
	End program inputreader

	subroutine umatrix(n,nfrs,nbins)
	integer i,j,k,imin,jmin,a,nfe,ir,nbinsrot
	real, dimension(n) :: rx,ry,rz,lavm,sigfe,fricorr,pvol
	real, dimension(n) :: lx,ly,lz,lmag,avfe,avfesq,fenorm
	real, dimension(n,n) :: sigij,rij,qinvm,qm
	real, dimension(n,nfrs) :: xix,xiy,xiz,dipcorr,xim,
     &theta,phi
	real dotpij,um,rrij,bl,hrtheta,hrphi,Rb,T,r,dr
	integer itheta,iphi
	real hisang(n,-nbins:nbins,-nbins:nbins)
	character(32)protname
	character(16)aa,ii,cbins
	real hisp,hismax,delha,rdeg,degr,hnorm(n),x,y,z
	real feang(n,-nbins:nbins,-nbins:nbins),femax,pi,delr
	real testnorm,dc
c	nfrs=1000 !just for testiing!
	Rb=.00198 !(boltzmanns constant in kcal/mol*K)
	open(unit=10,file='temp')
	read(10,*)T
	close(10)
	felim=0.0
	femin=0.0
	feminp=0.0
	sigfe=0.0
	fricorr=0.0
	avfe=0.0
	avfesq=0.0
	rij=0.0
	hisp=100.0
	hismax=0.0
	xix=0.0
	xiy=0.0
	xiz=0.0
	xim=0.0
	qinvm=0.0
	qm=0.0
	dipcorr=0.0	
	xim=0.0
	theta=0.0
	phi=0.0
	hisang=0.0
	hrtheta=0.0
	hrphi=0.0
	itheta=0
	iphi=0
	pi=3.1415927
	delha=(2.0*360.0)/real(2*nbins)
	degr=((2.0*pi)/360.0) !deg to rad
	rdeg=1.0/degr !rad to deg
	pvol=0.0
	fenorm=0.0
	r=0.0
	dr=5.0/(real(nfrs))
	ir=0
	dc=1.0/real(nfrs)

	delr=delha*degr
	write(*,*)"delr",delr
	hnorm=0.0
	open(unit=21,file='QINVmatrix',status='old')
	do i=1,n-1
	do j=1,n-1
	read(21,*)qinvm(i,j)
	end do
	end do
	open(unit=5,file="protname.txt",status='old')
	read(5,'(A)')protname
	close(5)
	rx=0.0
	ry=0.0
	rz=0.0
	lx=0.0
	ly=0.0
	lz=0.0
	lmag=0.0
	lavm=0.0
	dotpij=0.0
	sigij=0.0
	um=0.0
	rrij=0.0
	rij=0.0
	bl=0.0
	imin=0
	jmin=0

c	testnorm=0.0
c	do i=1,nbins/2
c	do j=1,nbins
c	do k=1,100
c	testnorm=testnorm+.5*delr*delr*dr*(((k*dr)**2)*
c     &sin(i*delr)+(((k-1)*dr)**2)*sin((i-1)*delr))
c	end do
c	end do
c	end do
c	write(*,*)"testnorm:",testnorm,"check:",(4./3.)*pi*
c     &(100.*dr)**3

	!read from trajectory
	open(unit=11,file=trim(protname)//'.g96',status='old')
	!skip first 7,now read and calculate stuff
	do i=1,7
	read(11,*)
	end do

	do k=1,nfrs
	do j=1,n
	read(11,*)rx(j),ry(j),rz(j)
	end do
	do j=1,n-1
	lx(j)=rx(j+1)-rx(j)
	ly(j)=ry(j+1)-ry(j)
	lz(j)=rz(j+1)-rz(j)
c	lmag(j)=(lx(j)**2+ly(j)**2+lz(j)**2)**.5
c	lavm(j)=lavm(j)+lmag(j)
	end do

	!skip 8 lines
	do j=1,8
	read(11,*)
	end do
!	calculating instantaneous mode vector
	do a=1,n-1 !mode loop
	do j=1,n-1 !residue loop
	xix(a,k)=qinvm(a,j)*lx(j)+xix(a,k)
	xiy(a,k)=qinvm(a,j)*ly(j)+xiy(a,k)
	xiz(a,k)=qinvm(a,j)*lz(j)+xiz(a,k)
	end do
	xim(a,k)=(xix(a,k)**2+xiy(a,k)**2+xiz(a,k)**2)**.5
	end do
!	calculate theta, phi
	do a=1,n-1
	theta(a,k)=acos(xiz(a,k)/xim(a,k))
	phi(a,k)=atan(xiy(a,k)/xix(a,k))
	if(xix(a,k).lt.0.0)phi(a,k)=phi(a,k)+pi
	theta(a,k)=theta(a,k)*rdeg
	if(phi(a,k).lt.0.0)phi(a,k)=phi(a,k)+2.0*pi
	phi(a,k)=phi(a,k)*rdeg
c	if(a.eq.4)write(*,*)theta(a,k),phi(a,k)
	end do

	!write into histogram
	do a=1,n-1
	hrtheta=theta(a,k)/delha
	hrphi=phi(a,k)/delha
	itheta=nint(hrtheta)
	iphi=nint(hrphi)
	hisang(a,itheta,iphi)=hisang(a,itheta,iphi)+dc
c	if(a.eq.4)write(*,*)itheta,iphi,hisang(a,itheta,iphi)
	end do
	

	!come out of time loop
	end do
	


	!normalize
c	do i=1,n-1
c	lavm(i)=lavm(i)/(real(nfrs))
c	write(*,*)lavm(i)
c	end do

c	open(unit=31,file="modenorm.dat")
	!change to probability per solid angle
	do a=1,n-1
	do i=1,nbins/2-1
	do j=0,nbins-1
	hisang(a,i,j)=hisang(a,i,j)/(sin(i*delr)*delr*delr)
	end do
	end do
	end do

	do a=1,n-1
	do i=1,nbins/2
	do j=1,nbins-1
	hnorm(a)=hnorm(a)+.5*delr*delr*(hisang(a,i,j)
     &*sin(i*delr)+hisang(a,i-1,j-1)*sin((i-1)*delr))
	end do
	end do
	write(*,*)a,"norm:",hnorm(a)
c	write(31,*)a,hnorm(a)
	end do
c	close(31)

	!normalize
	do a=1,n-1
	do i=0,nbins/2
	do j=0,nbins-1
	hisang(a,i,j)=hisang(a,i,j)/hnorm(a)
	end do
	end do
	end do

	!test normalization
	do a=1,n-1
	testnorm=0.0
	do i=1,nbins/2
	do j=1,nbins-1
	testnorm=testnorm+.5*delr*delr*(hisang(a,i,j)*
     &sin(i*delr)+hisang(a,i-1,j-1)*sin((i-1)*delr))
	end do
	end do
	write(*,*)a,"testnorm:",testnorm
	end do

	!prob volume
c	open(unit=16,file='pvol.dat')
c	do a=1,n-1
c	do i=2,nbins/2-1
c	do j=1,nbins-1
c	ir=nint(hisang(a,i,j)/dr)
c	if(ir.ne.0)then
c	do k=1,ir
c	pvol(a)=pvol(a)+.5*delr*delr*dr*(((k*dr)**2)
c     &*sin(i*delr)+(((k-1)*dr)**2)*sin((i-1)*delr))
c	end do
c	end if
c	end do
c	end do
c	write(*,*)a,"pvol:",pvol(a)
c	write(16,*)a,pvol(a)
c	end do

	femax=-Rb*T*log(1.0/real(nfrs))
	write(*,*)femax
	do a=1,n-1
	do i=1,nbins/2-1
	do j=0,nbins-1
	if(hisang(a,i,j).ne.0.0)then !change to pmf
	feang(a,i,j)=-Rb*T*log(hisang(a,i,j))
	end if
	if(hisang(a,i,j).eq.0.0)feang(a,i,j)=femax
	end do
	end do
	end do

	write(cbins,*)nbins
	cbins=adjustl(cbins)
	open(unit=110,file="fricorr_rect_"//trim(cbins)//".dat")
	do a=1,n-1
	do i=1,nbins/2-1
	do j=1,nbins-1
	if(feang(a,i,j).lt..5*femax)then
	avfe(a)=avfe(a)+feang(a,i,j)
	avfesq(a)=avfesq(a)+feang(a,i,j)**2
	fenorm(a)=fenorm(a)+1.0
	end if
	end do
	end do
	avfe(a)=avfe(a)/(fenorm(a))
	avfesq(a)=avfesq(a)/(fenorm(a))
c	write(*,*)"avfe:",avfe(a),"1/4pi",-Rb*T*log(1./(4.*pi))
	write(*,*)"fenorm:",fenorm(a)
	sigfe(a)=(avfesq(a)-avfe(a)**2)**.5
	write(*,*)"?",avfesq(a),avfe(a)**2
	fricorr(a)=exp(sigfe(a)/(Rb*T))
	write(*,*)a,"efluc:",sigfe(a),"kcal/mol"
	write(110,*)fricorr(a)
	end do
	close(110)

!	open histogram files
	do i=1,n-1
	write(ii,*)i
	ii=adjustl(ii)
	open(unit=100+i,file='fe_'//trim(ii)//'.dat')
	end do

!write 2D histograms
	do a=1,n-1
	do j=1,nbins/2-1
	do k=1,nbins-1
c	if(feang(a,j,k).lt..5*femax)then
	write(100+a,*)j*delha,k*delha,feang(a,j,k)
c	end if
c	x=hisang(a,j,k)*cos(k*delr)*sin(j*delr)
c	y=hisang(a,j,k)*sin(k*delr)*sin(j*delr)
c	z=hisang(a,j,k)*cos(j*delr)
c	write(200+a,*)x,y,z
	end do
	write(100+a,*)
	end do
	end do

	end subroutine

