	program inputreader
	integer nfrs,n,natoms,nmol,na,nskip,nmc
	character(32)cnmol
	open(unit=5,file="../protname.txt",status='old')
	read(5,*)
	read(5,*)n
	read(5,*)nfrs
	close(5)
	open(unit=2,file="../nmol.dat",status='old')
	read(2,*)nmol
	close(2)

	natoms=0
	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)	
	open(unit=2,file="../natoms"//trim(cnmol)//".dat",status='old')
	read(2,*)na
	close(2)
	natoms=natoms+na
	end do

	nbins=90

	nskip=1
	nfrs=nfrs/nskip
	nmc=8 !number of modes calculating for
	write(*,*)n,nfrs,natoms,nmol
	call umatrix(n,nfrs,nbins,natoms,nmol,nmc)
	End program inputreader

	subroutine umatrix(n,nfrs,nbins,natoms,nmol,nmc)
	integer i,j,k,imin,jmin,a,nfe,ir,nbinsrot,natoms,inml,nmh
	real, dimension(n) :: rx,ry,rz,lavm,sigfe,fricorr,pvol
	real, dimension(natoms) :: rxa,rya,rza
	real, dimension(n) :: lx,ly,lz,lmag,avfe,avfesq,fenorm
	real, dimension(nmc,-nbins:nbins,-nbins:nbins,n)
     & :: rxav,ryav,rzav
	real, dimension(nmc,-nbins:nbins,-nbins:nbins,natoms)
     & :: rxava,ryava,rzava
	real, dimension(nmc,-nbins:nbins,-nbins:nbins)
     & :: avcount
	real, dimension(n,n) :: sigij,rij,qinvm,qm
	real, dimension(n) :: xix,xiy,xiz,dipcorr,xim,
     &theta,phi
	real dotpij,um,rrij,bl,hrtheta,hrphi,Rb,T,r,dr,delphi
	integer itheta,iphi,nmol,nres(nmol),nt
	real hisang(n,-nbins:nbins,-nbins:nbins)
	character(32)protname
	character(64)aa,ii,jj
	real hisp,hismax,delha,rdeg,degr,hnorm(n),x,y,z
	real feang(n,-nbins:nbins,-nbins:nbins),femax,pi,delr
	real testnorm,dc,place
	character(32)cnmol

	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)	
	open(unit=2,file="../nres"//trim(cnmol)//".dat",status='old')
	read(2,*)nres(i)
	close(2)
	end do
!	nfrs=10 !just for testiing!
	Rb=.00198 !(boltzmanns constant in kcal/mol*K)
	T=300.0
	
	inml=4 !modes of interest
	nmh=12

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
	place=0.0
	degr=((2.0*pi)/360.0) !deg to rad
	rdeg=1.0/degr !rad to deg
	pvol=0.0
	fenorm=0.0
	r=0.0
	dr=5.0/(real(nfrs))
	ir=0
	dc=1.0/real(nfrs)
	avcount=0.0

	delr=delha*degr
	write(*,*)"delr",delr
	hnorm=0.0
	open(unit=21,file='../QINVmatrix',status='old')
	do i=1,n-nmol
	do j=1,n-nmol
	read(21,*)qinvm(i,j)
	end do
	end do
	open(unit=5,file="../protname.txt",status='old')
	read(5,'(A)')protname
	close(5)
	rx=0.0 !CG coordinates (n)
	ry=0.0
	rz=0.0
	rxa=0.0 !all atom coordinates (natoms)
	rya=0.0
	rza=0.0
	lx=0.0 !bond length coordinates (n-1)
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
	rxav=0.0 !average for CG coordinates
	ryav=0.0
	rzav=0.0
	rxava=0.0 !average for all atom coordinates
	ryava=0.0
	rzava=0.0
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
	open(unit=11,file='../'//trim(protname)//'.g96',
     &status='old')
	open(unit=12,file='coo.g96',
     &status='old')
	!skip first 7,now read and calculate stuff
	do i=1,7
	read(11,*)
	read(12,*)
	end do

	do l=1,nfrs
!	write(*,*)l
	if(mod(l,100).eq.0)write(*,*)"frame:",l
	do j=1,n !reading in CG coordinates
	read(11,*)rx(j),ry(j),rz(j)
	end do
	do j=1,natoms !reading in all atom coordinates
	read(12,*)rxa(j),rya(j),rza(j)
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
	read(12,*)
	end do
!	calculating instantaneous mode vector
	xix=0.0
	xiy=0.0
	xiz=0.0
	xim=0.0
	theta=0.0
	phi=0.0
	do a=inml,nmh !only looking at this mode for now !mode loop
	do j=1,n-nmol !residue loop
	xix(a)=qinvm(a,j)*lx(j)+xix(a)
	xiy(a)=qinvm(a,j)*ly(j)+xiy(a)
	xiz(a)=qinvm(a,j)*lz(j)+xiz(a)
	end do
	xim(a)=(xix(a)**2+xiy(a)**2+xiz(a)**2)**.5
	end do
!	calculate theta, phi
	do a=inml,nmh !only looking at this mode for now
	theta(a)=acos(xiz(a)/xim(a))
	phi(a)=atan(xiy(a)/xix(a))
	if(xix(a).lt.0.0)phi(a)=phi(a)+pi
	theta(a)=theta(a)*rdeg
	if(phi(a).lt.0.0)phi(a)=phi(a)+2.0*pi
	phi(a)=phi(a)*rdeg
c	if(a.eq.4)write(*,*)theta(a,k),phi(a,k)
	end do

	!write into histogram: need to break phi up into different number of bins dependent upon sin theta
	do a=inml,nmh !only looking at this mode for now
	delphi=360./real(nint((nbins*sin(theta(a)*degr))))
	hrtheta=theta(a)/delha
	hrphi=phi(a)/delphi
	itheta=nint(hrtheta)
	iphi=nint(hrphi)
	hisang(a,itheta,iphi)=hisang(a,itheta,iphi)+dc
c	if(a.eq.4)write(*,*)itheta,iphi,hisang(a,itheta,iphi)
	!calculate average structure at each orientation
	avcount(a,itheta,iphi)=avcount(a,itheta,iphi)+1.0
	do j=1,n !residue loop for av structure in CG coordinates
	rxav(a,itheta,iphi,j)=rxav(a,itheta,iphi,j)+rx(j)
	ryav(a,itheta,iphi,j)=ryav(a,itheta,iphi,j)+ry(j)
	rzav(a,itheta,iphi,j)=rzav(a,itheta,iphi,j)+rz(j)
	end do
	do j=1,natoms !residue loop for av structure
	rxava(a,itheta,iphi,j)=rxava(a,itheta,iphi,j)+rxa(j)
	ryava(a,itheta,iphi,j)=ryava(a,itheta,iphi,j)+rya(j)
	rzava(a,itheta,iphi,j)=rzava(a,itheta,iphi,j)+rza(j)
	end do

	end do !end mode loop

	end do !end time loop

	write(*,*)"read done"

	!normalize structures
	do a=inml,nmh
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
c	delphi=(2.*pi)/(real(iphi))
	do j=0,iphi
	do k=1,n !CG
	rxav(a,i,j,k)=rxav(a,i,j,k)/avcount(a,i,j)
	ryav(a,i,j,k)=ryav(a,i,j,k)/avcount(a,i,j)
	rzav(a,i,j,k)=rzav(a,i,j,k)/avcount(a,i,j)
	end do
	do k=1,natoms !allatom
	rxava(a,i,j,k)=rxava(a,i,j,k)/avcount(a,i,j)
	ryava(a,i,j,k)=ryava(a,i,j,k)/avcount(a,i,j)
	rzava(a,i,j,k)=rzava(a,i,j,k)/avcount(a,i,j)
	end do
	end do
	end do
	end do
	
!	write structure files
	do a=inml,nmh
	write(*,*)"writing mode:",a
	write(aa,*)a
	aa=adjustl(aa)
	do i=1,nbins/2-1
	iphi=nint(nbins*sin(i*delr))
	delphi=(360.)/(real(iphi))
	place=i*delha
	write(ii,'(F4.0)')place
c	write(ii,*)i
	ii=adjustl(ii)
c	write(*,*)"theta:",trim(ii)
	do j=0,iphi
	place=j*delphi
c	write(*,*)place
	
	if(hisang(a,i,j).ne.0.0)then
	write(jj,'(F4.0)')place
c	write(jj,*)j
	jj=adjustl(jj)	
c	write(*,*)"phi:",trim(jj)
	open(unit=100,file='av_m'//trim(aa)//'_theta'// !CG
     &trim(ii)//'_phi'//trim(jj))
	do k=1,n
	write(100,*)rxav(a,i,j,k),ryav(a,i,j,k),rzav(a,i,j,k)
	end do
	close(100)

	open(unit=101,file='avall_m'//trim(aa)//'_theta'//
     &trim(ii)//'_phi'//trim(jj))
	write(*,*)'avall_m'//trim(aa)//'_theta'//
     &trim(ii)//'_phi'//trim(jj)
	do k=1,natoms
	write(101,*)rxava(a,i,j,k),ryava(a,i,j,k),rzava(a,i,j,k)
	end do
	close(101)
	end if
	end do !end phi loop
	end do !end theta loop
	end do !end mode loop


	end subroutine

