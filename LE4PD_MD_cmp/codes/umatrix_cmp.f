	program inputreader
	integer nfrs,n,nmol
	open(unit=5,file="protname.txt",status='old')
	read(5,*)
	read(5,*)n
	read(5,*)nfrs
	close(5)
	write(*,*)n,nfrs
	open(unit=2,file="nmol.dat",status='old')
	read(2,*)nmol
	close(2)
!	call nlist(n)
	call umatrix(n,nmol,nfrs)
	End program inputreader

	subroutine umatrix(n,nmol,nfrs)
	integer i,j,k,l,imin,jmin,n,nfrs,nmol,nres(nmol),nt
	real, dimension(n) :: rx,ry,rz,lavm,lavmsq
	real, dimension(n) :: lx,ly,lz,lmag
	real, dimension(n,n) :: sigij,rij
	real dotpij,um,rrij,bl,blsq
	character(32)protname,cnmol
	real rijp,rijmin
	rij=0.0
	rijp=0.0
	rijmin=0.0
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
	rx=0.0
	ry=0.0
	rz=0.0
	lx=0.0
	ly=0.0
	lz=0.0
	lmag=0.0
	lavm=0.0
	lavmsq=0.0
	dotpij=0.0
	sigij=0.0
	um=0.0
	rrij=0.0
	rij=0.0
	bl=0.0
	imin=0
	jmin=0
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
	lmag(j)=(lx(j)**2+ly(j)**2+lz(j)**2)**.5
	lavm(j)=lavm(j)+lmag(j)
	lavmsq(j)=lavmsq(j)+lmag(j)**2
	if(k.eq.nt)then !drop bonds between molecules
!	write(*,*)nt
	lavm(j)=lavm(j)-lmag(j)
	lavmsq(j)=lavmsq(j)-lmag(j)**2
	j=j-1
	i=i+1
	nt=nt+nres(i)
	end if
	j=j+1
	end do
	do i=1,n-nmol
	do j=1,n-nmol
	dotpij=lx(i)*lx(j)+ly(i)*ly(j)+lz(i)*lz(j)
	sigij(i,j)=sigij(i,j)+dotpij
	end do
	end do
	!calculate rij
	do i=1,n
	do j=1,n
	if(i.eq.j)then
	rij(i,j)=0.0
	else
	rrij=(rx(i)-rx(j))**2+(ry(i)-ry(j))**2+(rz(i)-rz(j))**2
	rrij=rrij**.5
	rrij=1.0/rrij
	rij(i,j)=rij(i,j)+rrij
	end if
	end do
	end do
	!skip 8 lines
	do j=1,8
	read(11,*)
	end do
	!come out of time loop
	end do
	!normalize
	do i=1,n-nmol
	lavm(i)=lavm(i)/(real(nfrs))
	lavmsq(i)=lavmsq(i)/(real(nfrs))
c	write(*,*)lavm(i)
	end do
	do i=1,n-nmol
	do j=1,n-nmol
	sigij(i,j)=sigij(i,j)/(real(nfrs))
	sigij(i,j)=sigij(i,j)/(lavm(i)*lavm(j))
	end do
	end do
	!assign Umatrix
	open(unit=3, file='Umatrix')
	um=0
	write(3,*)n-nmol
	do i=1,n-nmol
	do j=1,n-nmol
	um=sigij(i,j)
	write(3,*)um
	end do
	end do
	!assign Rij
	open(unit=17,file="Rij")
	do i=1,n
	do j=1,n
	rij(i,j)=rij(i,j)/real(nfrs)
	write(17,*)rij(i,j)
	if(rij(i,j).gt.rijp.and.rij(i,j).gt.0.0)then
	rijmin=rij(i,j)
	imin=i
	jmin=j
	rijp=rij(i,j)
	end if
	end do
	end do
	close(17)
	open(unit=21,file="Rij_min")
	write(21,*)1./rijmin,imin,jmin
	close(21)
	!assign length
	open(unit=18,file="length")
	blsq=0.0
	bl=0.0
	do i=1,n-nmol
	write(18,*)lavm(i)
	bl=bl+lavm(i)
	blsq=blsq+lavmsq(i)
	end do
	close(18)
	bl=bl/real(n-nmol)
	blsq=blsq/real(n-nmol)
	open(unit=19,file='avbl')
	write(19,*)bl
	close(19)
	open(unit=19,file='avblsq')
	write(19,*)blsq
	close(19)
	
	end subroutine
