	program inputreader
	integer nfrs,n,nmol,nbins
	open(unit=5,file="protname.txt",status='old')
	read(5,*)
	read(5,*)n
	read(5,*)nfrs
	close(5)
	open(unit=2,file="nmol.dat",status='old')
	read(2,*)nmol
	close(2)
	nbins=60
	write(*,*)n,nfrs
	call umatrix(n,nmol,nfrs,nbins)
	End program inputreader

	subroutine umatrix(n,nmol,nfrs,nbins)
	integer i,j,k,imin,jmin,a,nfe,ir,nbinsrot,imad,imadmid
	real, dimension(n) :: rx,ry,rz,lavm,sigfe,fricorr,pvol,
     &fmax,fmin,fmaxp,fminp,fbg
	real, dimension(n) :: lx,ly,lz,lmag,avfe,avfesq,fenorm
	real, dimension(n,n) :: sigij,rij,qinvm,qm
	real, dimension(n,nfrs) :: xix,xiy,xiz,dipcorr,xim,
     &theta,phi
	real dotpij,um,rrij,bl,hrtheta,hrphi,Rb,T,r,dr,delphi
	integer itheta,iphi,nbins,nmol,n,nres(nmol),nt
	real hisang(n,-nbins:nbins,-nbins:nbins)
	character(32)protname,cnmol
	character(16)aa,ii,cbins
	real hisp,hismax,delha,rdeg,degr,hnorm(n),x,y,z,emad
	real feang(n,-nbins:nbins,-nbins:nbins),femax,pi,delr
	real testnorm,dc,fmad(nbins*nbins),fmadord(nbins*nbins)
c	nfrs=10000 !just for testiing!
	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)	
	open(unit=2,file="nres"//trim(cnmol)//".dat",status='old')
	read(2,*)nres(i)
	close(2)
	end do
	Rb=.00198 !(boltzmanns constant in kcal/mol*K)
	T=300.0
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
	fmax=0.0
	fmaxp=0.0
	fmin=0.0
	fminp=200.0
	fbg=0.0
	fmad=0.0
	fmadord=0.0

	delr=delha*degr
	write(*,*)"delr",delr
	hnorm=0.0
	open(unit=21,file='QINVmatrix',status='old')
	do i=1,n-nmol
	do j=1,n-nmol
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
c	do j=0,iphi

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

	do l=1,nfrs
	do j=1,n
	read(11,*)rx(j),ry(j),rz(j)
	end do
	j=1
	i=1 !mol number
	nt=nres(1)
	do k=1,n-1
!	if(l.eq.10)write(*,*)j,k
	lx(j)=rx(k+1)-rx(k)
	ly(j)=ry(k+1)-ry(k)
	lz(j)=rz(k+1)-rz(k)
	if(k.eq.nt)then !drop bonds between molecules
!	write(*,*)nt
!	lavm(j)=lavm(j)-lmag(j)
!	lavmsq(j)=lavmsq(j)-lmag(j)**2
	j=j-1
	i=i+1
	nt=nt+nres(i)
	end if
	j=j+1
	end do

	!skip 8 lines
	do j=1,8
	read(11,*)
	end do
!	calculating instantaneous mode vector
	do a=1,n-nmol !mode loop
	do j=1,n-nmol !residue loop
	xix(a,l)=qinvm(a,j)*lx(j)+xix(a,l)
	xiy(a,l)=qinvm(a,j)*ly(j)+xiy(a,l)
	xiz(a,l)=qinvm(a,j)*lz(j)+xiz(a,l)
	end do
	xim(a,l)=(xix(a,l)**2+xiy(a,l)**2+xiz(a,l)**2)**.5
	end do
!	calculate theta, phi
	do a=1,n-nmol
	theta(a,l)=acos(xiz(a,l)/xim(a,l))
	phi(a,l)=atan(xiy(a,l)/xix(a,l))
	if(xix(a,l).lt.0.0)phi(a,l)=phi(a,l)+pi
	theta(a,l)=theta(a,l)*rdeg
	if(phi(a,l).lt.0.0)phi(a,l)=phi(a,l)+2.0*pi
	phi(a,l)=phi(a,l)*rdeg
c	if(a.eq.4)write(*,*)theta(a,l),phi(a,l)
	end do

	!write into histogram: need to break phi up into different number of bins dependent upon sin theta
	do a=1,n-nmol
	delphi=360./real(nint((nbins*sin(theta(a,l)*degr))))
	hrtheta=theta(a,l)/delha
	hrphi=phi(a,l)/delphi
	itheta=nint(hrtheta)
	iphi=nint(hrphi)
	hisang(a,itheta,iphi)=hisang(a,itheta,iphi)+dc
c	if(a.eq.4)write(*,*)itheta,iphi,hisang(a,itheta,iphi)
	end do
	

	!come out of time loop
	end do
	


	!normalize
c	do i=1,n-nmol
c	lavm(i)=lavm(i)/(real(nfrs))
c	write(*,*)lavm(i)
c	end do

	!change to probability per solid angle
c	do a=1,n-nmol
c	do i=1,nbins/2-1
c	iphi=nint(nbins*sin(i*delr))
c	do j=0,iphi
c	hisang(a,i,j)=hisang(a,i,j)/(sin(i*delr)*delr*delr)
c	end do
c	end do
c	end do

	do a=1,n-nmol
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
	delphi=(2.*pi)/(real(iphi))
c	write(*,*)"theta:",i*delha,"phibins:",iphi
	do j=1,iphi
	hnorm(a)=hnorm(a)+.5*delr*delphi*(hisang(a,i,j)
     &*sin(i*delr)+hisang(a,i-1,j-1)*sin((i-1)*delr))
	end do
	end do
	write(*,*)a,"norm:",hnorm(a)
	end do

	!normalize
	do a=1,n-nmol
	do i=0,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
c	delphi=(2.*pi)/(real(iphi))
	do j=0,iphi
	hisang(a,i,j)=hisang(a,i,j)/hnorm(a)
	end do
	end do
	end do


	!test normalization
	do a=1,n-nmol
	testnorm=0.0
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
	delphi=(2.*pi)/(real(iphi))
	do j=1,iphi
	testnorm=testnorm+.5*delr*delphi*(hisang(a,i,j)*
     &sin(i*delr)+hisang(a,i-1,j-1)*sin((i-1)*delr))
	end do
	end do
	write(*,*)a,"testnorm:",testnorm
	end do

	!prob volume
c	open(unit=16,file='pvol.dat')
c	do a=1,n-nmol
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
	do a=1,n-nmol
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
c	delphi=(2.*pi)/(real(iphi))
	do j=0,iphi
	if(hisang(a,i,j).ne.0.0)then !change to pmf
	feang(a,i,j)=-Rb*T*log(hisang(a,i,j))
	end if
	if(hisang(a,i,j).eq.0.0)feang(a,i,j)=femax
	end do
	end do
	end do

	write(cbins,*)nbins
	cbins=adjustl(cbins)
	open(unit=110,file="fricorr_mp_"//trim(cbins)//".dat")
	open(unit=111,file="feminmax_mp_"//trim(cbins)//".dat")
	open(unit=112,file="femin_mp_"//trim(cbins)//".dat")
	do a=1,n-nmol
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
c	delphi=(2.*pi)/(real(iphi))
	do j=1,iphi-1
	if(feang(a,i,j).lt..5*femax)then
	 avfe(a)=avfe(a)+feang(a,i,j)
	 avfesq(a)=avfesq(a)+feang(a,i,j)**2
	 fenorm(a)=fenorm(a)+1.0
	  if(feang(a,i,j).le.fminp(a))then
	  fmin(a)=feang(a,i,j)
	  fminp(a)=feang(a,i,j)
	  end if
	  if(feang(a,i,j).gt.fmaxp(a))then
	  fmax(a)=feang(a,i,j)
	  fmaxp(a)=feang(a,i,j)
	  end if
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
	write(110,*)sigfe(a)
	write(111,*)fmax(a)-fmin(a)
	write(112,*)fmin(a)
	end do
	close(110)
	close(111)
	close(112)

! typical barrier from ground from median absolute deviation
	open(unit=111,file="fmad_mp_"//trim(cbins)//".dat")
	do a=1,n-nmol
	imad=0
	fmad=0.0
	fmadord=0.0
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
c	delphi=(2.*pi)/(real(iphi))
	do j=1,iphi-1
	if(hisang(a,i,j).gt.2.*dc)then
	 imad=imad+1
	 fmad(imad)=abs(feang(a,i,j)-fmin(a))
	end if
	end do
	end do

	imadmid=imad/2
	do i=1,imad
	fmadord(i)=maxval(fmad)
	fmad(maxloc(fmad))=0.0
	end do
	do i=1,imad
	write(*,*)i,"devE:",fmadord(i)
	end do
	emad=fmadord(imadmid)

	write(*,*)a,"mode mad:",emad,"kcal/mol"
	write(111,*)emad
	end do
	close(111)

!	open histogram files
	do i=1,n-nmol
	write(ii,*)i
	ii=adjustl(ii)
	open(unit=100+i,file='fempa_'//trim(ii)//'.dat')
c	open(unit=200+i,file='prob_'//trim(ii)//'.dat')
	end do

!write 2D histograms
	do a=1,n-nmol
	do j=1,nbins/2-1
	iphi=nint(nbins*sin(j*delr))
	delphi=(360.)/(real(iphi))
	do k=0,iphi
c	if(feang(a,j,k).lt..5*femax)then
	write(100+a,*)j*delha,k*delphi,feang(a,j,k)
c	end if
c	x=hisang(a,j,k)*cos(k*delphi)*sin(j*delr)
c	y=hisang(a,j,k)*sin(k*delphi)*sin(j*delr)
c	z=hisang(a,j,k)*cos(j*delr)
c	write(200+a,*)j*delha,k*delphi,hisang(a,j,k)
c	write(200+a,*)j*delha,k*delha,hisang(a,j,k)
	end do
	write(100+a,*)
c	write(200+a,*)
	end do
	end do

	end subroutine

