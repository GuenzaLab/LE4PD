	program inputreader
	integer n,io,i,nmol
	double precision fratio
	character(32)protname
	open(unit=114,file='protname.txt',status='old')
	read(114,*)
	read(114,*)n
	close(114)
	open(unit=114,file='nmol.dat',status='old')
	read(114,*)nmol
	close(114)
	fratio=.25
	do i=1,200
	open(unit=10,file='fratio')
	write(10,*)fratio
	close(10)
	call frictioneditor(n,nmol)
	open(unit=11,file='status')
	read(11,*)io
	close(11)
	write(*,*)fratio,io
	if(io.eq.1)then
	fratio=fratio-.003
	open(unit=10,file='fratio')
	write(10,*)fratio
	close(10)
       EXIT
	end if
	fratio=fratio-.0015
	end do
	call frictioneditor(n,nmol)
	end program inputreader


	subroutine frictioneditor(ntot,nmol)
	real van,friwt,frit,rw,rv,rp,factor,vp,temp,sigconst
	real sigma,avfr,bl,avfrw,vv,fd20
	real, dimension(ntot) :: friw, fri
	double precision UM(ntot-nmol,ntot-nmol),UMI(ntot-nmol,ntot-nmol),HM(ntot,ntot)
	double precision Rij(ntot,ntot),LAM(ntot,ntot-nmol),LUM(ntot-nmol,ntot-nmol)
	double precision fratio,LM(ntot-nmol,ntot-nmol),LMI(ntot-nmol,ntot-nmol),XM(ntot,ntot),XMI(ntot,ntot)
	double precision AM(ntot-nmol,ntot),AMT(ntot,ntot-nmol)
	double precision work((ntot-nmol)*(ntot-nmol)),eiglam(ntot-nmol),eigmu(ntot-nmol),eignu(ntot-nmol)
	double precision Atest(ntot-nmol,ntot-nmol),LUI(ntot-nmol,ntot-nmol)
	double precision QM(ntot-nmol,ntot-nmol),QMI(ntot-nmol,ntot-nmol),eiglamI(ntot-nmol)
	double precision QAM(ntot-nmol,ntot-nmol),QMO(ntot-nmol,ntot-nmol),QMIO(ntot-nmol,ntot-nmol)
	double precision eiglamO(ntot-nmol),eigmuO(ntot-nmol),eignuO(ntot-nmol),eigmuent(ntot-nmol),entropy
	character(32)protname,cnmol
	integer i,j,k,l,n,nm1,io,ipiv(ntot),ilo,ihi,order(ntot),mineig(1),a,nmol,nres(nmol),nt
	data   pi/3.141592654/
	data aKb/1.38066E-23/ !N*m/K
	data rB/.00198/ !kcal/mol*K
	n=ntot
	nm1=ntot-nmol
	write(*,*)nm1
	blsq=0.0
	open(unit=19,file='avbl',status='old')
	read(19,*)blsq
	close(19)
	blsq=blsq*blsq*1.002 !approximate fluctuation correction
	open(unit=19,file='temp',status='old')
	read(19,*)temp
	close(19)
	open(unit=19,file='fd20',status='old')
	read(19,*)fd20
	close(19)
	sigconst=3*aKb*Temp*1E-12/blsq/1E-18 !units of N*m/ps
	open(unit=100,file='avresrad',status='old') !radii of ASA water (Amst)
	open(unit=101,file="mrad.dat",status='old')  !radii of ASA total (Amst)
	open(unit=102,file="sigma")
	open(unit=103,file="internalv",status='old') !internal viscosity rescaling factor from solvent viscosity
	read(103,*)vv
	close(103)
	write(*,*)"factor int:",vv
	v=.2131590-1.96290E-3*temp+(.00246411*temp)**2+(-.0018462*temp)**3 !viscosity from fit to NIST at 1.0 atm
	write(*,*)"viscosity fit at T(K):",temp,"Visc(Pa*s):",v
	fh20=1.-fd20
	vadj=v*(1.23*fd20+fh20)
	open(unit=110,file="vadj")
	write(110,*)vadj
	close(110)
	van=0.0
	friwt=0.0
	frit=0.0
	rw=0.0
	rv=0.0
	rp=0.0
	friw=0.0
	fri=0.0
	factor=vv !ratio of internal viscosity to solvent viscosity
	vp=vadj*factor
	fratio=0.0
	sigma=0.0
	avfr=0.0
	avfrw=0.0
	do i=1,ntot
	read(100,*)rw
	read(101,*)rv
	if(rw.lt.rv)rp=(rv**2-rw**2)**.5
	if(rw.ge.rv)rp=0.0
	friwt=6.0*pi*rw*0.1d0*vadj+friwt
        frit=frit+6.0*pi*rp*0.1d0*vp+6.0*pi*rw*0.1d0*vadj
	friw(i)=6.0*pi*rw*0.1d0*vadj
        fri(i)=6.0*pi*rp*0.1d0*vp+6.0*pi*rw*0.1d0*vadj
	end do

	fratio=friwt/frit
	avfr=frit/real(ntot)
	avfrw=friwt/real(ntot)
	close(100)
	close(101)
	sigma=(sigconst)/(avfr*1E-9)
	open(unit=66,file='avfr')
	write(66,*)avfr*1E-9
	close(66)

	write(102,*)"sigma (1/ps):"
	write(102,*)sigma

	open(unit=40,file='fric') !friction coefficients
	write(40,*)avfr,avfrw
	do i=1,ntot
	write(40,*)friw(i),fri(i)
	end do
	close(40)

	UMI=0.0 !read in Umatrix, which is actually U^-1
	open(unit=8,file="Umatrix",status='old')
	read(8,*)
	do i=1,nm1
	do j=1,nm1
	read (8,*)UMI(i,j)
!	write(*,*)UMI(i,j)
	end do
	end do
	close(8)

	nres=0
	do i=1,nmol
	write(cnmol,*)i
	cnmol=adjustl(cnmol)
	open(unit=2,file="nres"//trim(cnmol)//".dat",status='old')
	read(2,*)nres(i)
	close(2)
!	write(*,*)nres(i)
	end do

	!M-matrix changes due to dropping psuedo bonds between ends of molecules
	XM=0.0
	k=0
	nt=1
	do i=1,ntot
	if(i.eq.nt)then !CM modes
	k=k+1
	do j=nt,nt+nres(k)-1
!	write(*,*)"XMps",nt,i,j,l
!	write(*,*)"CM:",i,j
	XM(i,j)=1./real(ntot)
	end do
	nt=nt+nres(k)
!	write(*,*)nt
	else
	XM(i,i)=1.
	XM(i,i-1)=-1.
	end if
	end do

	open(unit=10,file="Mmatrix",status='unknown')
	
	do i=1,ntot
        do j=1,ntot
	write (10,*)XM(i,j)
	end do
	write(10,*)
	end do
	close(10)

	open(unit=89,file='fratio',status='old')
	read(89,*)fratio
	close(89)                  
	open(unit=88,file="Rij",status='old')
	do i=1,ntot
        do j=1,ntot
        read(88,*)rij(i,j)
        end do
        end do
	close(88)

	HM=0.0
! CALCULATION OF H MATRIX  	
	do i=1,Ntot
	HM(i,i)=avfr/fri(i)	
!	HM(i,i)=1.0
	do j=1,i-1
!	HM(i,j)=(avfrw)/(6.0*pi*vadj)*rij(i,j)
	HM(i,j)=(fratio)*rij(i,j)
	HM(j,i)=HM(i,j)
	end do
	end do

	open(unit=10,file="Hmatrix",status='unknown')
	
	do i=1,ntot
        do j=1,ntot
	write (10,*)HM(i,j)
	end do
	end do
	close(10)

! L matrix
	AMT=0.0
	AM=0.0
	LM=0.0
	LMI=0.0
	LAM=0.0
	k=0
	l=0
	nt=1
	!skip over first and second 0 mode
	do i=1,ntot
	if(i.eq.nt)then
	k=k+1
	nt=nt+nres(k)
	else
	l=l+1
	do j=1,ntot
	AM(l,j)=XM(i,j)
	end do
	end if
	end do
	
	do i=1,ntot
	do j=1,nm1
	AMT(i,j)=AM(j,i)
	end do
	end do

	open(unit=10,file="amatrix",status='unknown')
	do i=1,nm1
	do j=1,ntot
	write(10,*)AM(i,j)
	end do
	write(10,*)
	end do	
	close(10)

	Atest=matmul(AM,AMT)
	open(unit=10,file="Atestmatrix",status='unknown')
	do i=1,nm1
        do j=1,nm1
	write(10,*)Atest(i,j)
	end do
	write(10,*)
	end do
	close(10)

	LAM=matmul(HM,AMT)
	LM=matmul(AM,LAM)

	open(unit=10,file="Lmatrix",status='unknown')
	do i=1,nm1
        do j=1,nm1
	write (10,*)LM(i,j)
	end do
	end do
	close(10)

	!Invert L
	LMI=LM

	call DGETRF(nm1, nm1, LMI, nm1, ipiv, io)
	write(*,*)"sgetrf (0 is success):",io
	call DGETRI(nm1, LMI, nm1, ipiv, work, nm1*nm1, io)
	write(*,*)"sgetri: (0 is success)",io

	open(unit=10,file="LImatrix",status='unknown')
	do i=1,nm1
        do j=1,nm1
	write (10,*)LMI(i,j)
	end do
	end do
	close(10)

!	do i=1,nm1
!        do j=1,nm1
!	write (*,*)UM(i,j)
!	end do
!	end do
	
	LUI=0.0
	LUI=matmul(UMI,LMI)

	open(unit=10,file="LUImatrix",status='unknown')
	do i=1,nm1
        do j=1,nm1
	write(10,*)LUI(i,j)
	end do
	end do
	close(10)

	!diagonalize for eigen expansion
	eiglam=0.0
!	call DSYEV("V","U",nm1,LUI,nm1,eiglam,work,nm1*nm1,io)
!	write(*,*)"ssyev: (0 is success)",io,work(1)
	call DGEEV("N","V",nm1,LUI,nm1,eiglam,eiglamI,Atest,nm1,QM,nm1,work,nm1*nm1,io)
	write(*,*)"DGEEV: (0 is success)",io,work(1)
	open(unit=40,file='status')
	if(minval(eiglam).lt.0.0) then
	write(*,*)"lambda neg",minval(eiglam)
	write(40,*)0
	else
	write(*,*)"pos. def."
	write(40,*)1
!	end if !take out

	!order eigenvalues and Qmatrix based upon lambda eigs
	order=0
	eiglamO=0.0
	do i=1,nm1
	eiglamO(i)=maxval(eiglam)
!	write(*,*)minloc(eiglam)
	mineig=maxloc(eiglam)
	order(i)=mineig(1)
!	write(*,*)eiglamO(i),order(i)
	eiglam(order(i))=1D-20
	end do
	do i=1,nm1
	eiglam(i)=eiglamO(i)
	end do

	QMO=0.0
	do i=1,nm1
	do j=1,nm1
	QMO(j,i)=QM(j,order(i))
	end do
	end do
	do i=1,nm1
	do j=1,nm1
	QM(i,j)=QMO(i,j)
	end do
	end do


	!Invert Q
	QMI=QM

	call DGETRF(nm1, nm1, QMI, nm1, ipiv, io)
	write(*,*)"sgetrf (0 is success):",io
	call DGETRI(nm1, QMI, nm1, ipiv, work, nm1*nm1, io)
	write(*,*)"sgetri: (0 is success)",io

	Atest=matmul(QMI,QM)
	open(unit=10,file="QmIQm",status='unknown')
	do i=1,nm1
        do j=1,nm1
	write (10,*)Atest(i,j)
	end do
	end do
	close(10)


	QAM=matmul(UMI,QM)
	Atest=matmul(QMI,QAM)
	open(unit=10,file="QtUIQ",status='unknown')
	do i=1,nm1
!	eigmu(i)=Atest(i,i)
!	eigmu(i)=1./eigmu(i)
        do j=1,nm1
	write(10,*)Atest(i,j)
	end do
	end do
	close(10)

!	get mu eigs and mode lengths from sum
	!now set up sum
	eigmu=0.0
	do a=1,nm1
	do i=1,nm1
	do j=1,nm1
	eigmu(a)=eigmu(a)+QMI(a,i)*UMI(i,j)*QMI(a,j)
	end do
	end do
!	eigmu(a)=1./eigmu(a)
	end do

	!order eigenvalues and Qmatrix based upon mu eigs
!	order=0
!	eigmuO=0.0
!	do i=1,nm1
!	eigmuO(i)=maxval(eigmu)
!	mineig=maxloc(eigmu)
!	order(i)=mineig(1)
!	eigmu(order(i))=1D-20
!	end do
!	do i=1,nm1
!	eigmu(i)=eigmuO(i)
!	eiglamO(i)=eiglam(i)
!	end do
!	do i=1,nm1
!	eiglam(i)=eiglamO(order(i))
!	end do

!	QMO=0.0
!	do i=1,nm1
!	do j=1,nm1
!	QMO(j,i)=QM(j,order(i))
!	end do
!	end do
!	do i=1,nm1
!	do j=1,nm1
!	QM(i,j)=QMO(i,j)
!	end do
!	end do


	!Invert Q
!	QMI=QM

!	call DGETRF(nm1, nm1, QMI, nm1, ipiv, io)
!	write(*,*)"sgetrf (0 is success):",io
!	call DGETRI(nm1, QMI, nm1, ipiv, work, nm1*nm1, io)
!	write(*,*)"sgetri: (0 is success)",io

	!assign eigenvectors to Qmatrix
	open(unit=10,file="Qmatrix",status='unknown')
	open(unit=11,file="QINVmatrix",status='unknown')
	do i=1,nm1
	do j=1,nm1
!	QMI(i,j)=QM(j,i)
	write (10,*)QM(i,j)
	write (11,*)QMI(i,j)
	end do
	end do
	close(10)
	close(11)

	Atest=matmul(LM,QM)
	Atest=matmul(QMI,Atest)
	open(unit=10,file="QtLQ",status='unknown')
	do i=1,nm1
	eignu(i)=Atest(i,i)
        do j=1,nm1
	write(10,*)Atest(i,j)
	end do
	end do
	close(10)

! entropy calculation as the determinant of bond correlation matrix
	eigmuent=0.0
	entropy=1.0
	call DSYEV("V","U",nm1,UMI,nm1,eigmuent,work,nm1*nm1,io)
	write(*,*)"ssyev: (0 is success)",io,work(1)
	do i=1,nm1-3 !global modes are biggest, so at end
	write(*,*)eigmuent(i)
	entropy=entropy+log((eigmuent(i)))
	end do
	entropy=(rB/2.0)*(entropy)
	write(*,*)"unnormalized entropy in quasiharmonic approximation:",entropy
	write(*,*)"entropy per bond:",entropy/real(nm1),"kcal/mol*k"
	open(unit=1,file='entropy')
	write(1,*)'#total entropy kcal/mol*k',entropy
	write(1,*)"#entropy per bond kcal/mol*k:"
	write(1,*)entropy/real(nm1)
	close(1)

!	eignu=0.0
!	call DSYEV("V","U",nm1,LMI,nm1,eignu,work,nm1*nm1,io)
!	write(*,*)"ssyev: (0 is success)",io,work(1)


	open(unit=99,file="lambda_eig",status='unknown')
	do i=1,nm1
	write(99,*)1./eiglam(i)
	end do
	close(99)
!	open(unit=99,file="lambda_eig_imaginary",status='unknown')
!	do i=1,nm1
!	write(99,*)eiglamI(i)
!	end do
!	close(99)

	open(unit=99,file="mu_eig",status='unknown')
	do i=1,nm1
	write(99,*)1./eigmu(i)
	end do
	close(99)
	open(unit=99,file="nu_eig",status='unknown')
	do i=1,nm1
	write(99,*)eignu(i)
	end do
	close(99)
!	open(unit=99,file="QINVmatrix",status='unknown')
!	do i=1,nm1
!	do k=1,nm1
!	write(99,*)xmiv(i,k)
!	end do
!	end do
!	close(99)
!	open(unit=99,file="Qmatrix",status='unknown')
!	do i=1,nm1
!	do k=1,nm1
!	write(99,*)xmivi(i,k)
!	end do
!	end do
!	close(99)

	endif !loop over pos. def.
	close(40)
      END 

!-----------------------------------------------------------------------------------------------------------------
	
	
