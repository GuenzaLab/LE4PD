	program pdbsplit !splits pdb into conformer structures
	integer i,j,k,anum,rnum,nmol,ios,nlines,natoms(10),ntot(10),maxlines,nc,l,m
	integer start,stop,nr,is,imin,jmin,stat
	character(16)protname,cnc,cnmol,chainprev,chain,restype
	character(128)line
	real mrad
	nc=1
	write(cnc,*)nc
	cnc=adjustl(cnc)

	!get number of lines, starting point
	open(unit=2,file="protname.txt",status='old')
	read(2,*)protname
	close(2)
	protname=adjustl(protname)
	nlines=0
	ios=0
	maxlines=150000
	start=0
	is=0
	stop=0
	nr=0
	ntot=0
	natoms=0
	nmol=1
	n=0
	write(cnmol,*)nmol
	cnmol=adjustl(cnmol)
	open(unit=13,file=trim(protname)//"_first.pdb")
	open(unit=23,file="mrad.dat")
!	open(unit=14,file=trim(protname)//trim(cnc)//"_"//trim(cnmol)//".pdb")
	chain(1:1)="A"
	chainprev(1:1)="A"
	do i=1,maxlines
	Read(13,'(A)',IOSTAT=ios)line
	If(ios /= 0) EXIT
	If (J == maxlines) then
	write(*,*) "Maxlines exceeded"
	STOP
	End If
	if(line(1:4) .eq. "ATOM" .AND. is .eq. 0)then
	start=nlines1
	is=1
	end if
	if(line(1:4) .eq. "ATOM")then
!	write(14,'(A)')line
	natoms(nmol)=natoms(nmol)+1
	read(line(22:23),'(A)')chain
	chain=adjustl(chain)
	end if
	if(line(14:15).eq."CA")then
	ntot(nmol)=ntot(nmol)+1
	n=n+1
	read(line(18:20),'(A)')restype
	restype=adjustl(restype)
	write(*,*)restype
	if(restype(1:3).eq."ALA")mrad=(113.0/(4*3.14))**.5
	if(restype(1:3).eq."ARG")mrad=(241.0/(4*3.14))**.5
	if(restype(1:3).eq."ASN")mrad=(158.0/(4*3.14))**.5
	if(restype(1:3).eq."ASP")mrad=(151.0/(4*3.14))**.5
	if(restype(1:3).eq."CYS")mrad=(140.0/(4*3.14))**.5
	if(restype(1:3).eq."GLN")mrad=(189.0/(4*3.14))**.5
	if(restype(1:3).eq."GLU")mrad=(183.0/(4*3.14))**.5
	if(restype(1:3).eq."GLY")mrad=( 85.0/(4*3.14))**.5
	if(restype(1:3).eq."HIS")mrad=(194.0/(4*3.14))**.5
	if(restype(1:3).eq."ILE")mrad=(182.0/(4*3.14))**.5
	if(restype(1:3).eq."LEU")mrad=(180.0/(4*3.14))**.5
	if(restype(1:3).eq."LYS")mrad=(211.0/(4*3.14))**.5
	if(restype(1:3).eq."MET")mrad=(204.0/(4*3.14))**.5
	if(restype(1:3).eq."PHE")mrad=(218.0/(4*3.14))**.5
	if(restype(1:3).eq."PRO")mrad=(143.0/(4*3.14))**.5
	if(restype(1:3).eq."SER")mrad=(122.0/(4*3.14))**.5
	if(restype(1:3).eq."THR")mrad=(146.0/(4*3.14))**.5
	if(restype(1:3).eq."TRP")mrad=(259.0/(4*3.14))**.5
	if(restype(1:3).eq."TYR")mrad=(229.0/(4*3.14))**.5
	if(restype(1:3).eq."VAL")mrad=(160.0/(4*3.14))**.5
	write(23,*)mrad
	end if
	if(is .eq. 1 .AND. line(1:3) .eq. "TER".or.is.eq.1.and.chain(1:1).ne.chainprev(1:1)) then
	write(*,*)chain(1:1),chainprev(1:1),n
!	close(14)
	open(unit=1,file="nres"//trim(cnmol)//".dat",position='append')
	write(1,*)ntot(nmol)
	close(1)
	open(unit=1,file="natoms"//trim(cnmol)//".dat",position='append')
	write(1,*)natoms(nmol)
	close(1)
	nmol=nmol+1
	write(cnmol,*)nmol
	cnmol=adjustl(cnmol)
!	close(14)
!	open(unit=14,file=trim(protname)//trim(cnc)//"_"//trim(cnmol)//".pdb")
	write(cnmol,*)nmol
	cnmol=adjustl(cnmol)
	end if	
	if(is .eq. 1 .AND. line(1:6) .eq. "ENDMDL") then
!	close(14, status='delete')
	chain(1:1)="A"
	chainprev(1:1)="A"
	n=0
	open(unit=1,file="nmol.dat",position='append')
	write(1,*)nmol-1
	close(1)
	ntot=0
	natoms=0
	nc=nc+1
	write(cnc,*)nc
	cnc=adjustl(cnc)
	nmol=1
	write(cnmol,*)nmol
	cnmol=adjustl(cnmol)
!	close(14)
!	open(unit=14,file=trim(protname)//trim(cnc)//"_"//trim(cnmol)//".pdb")
	end if
	write(cnmol,*)nmol
	cnmol=adjustl(cnmol)
	if(is .eq. 1 .AND. line(1:6) .eq. "MASTER")then
!	close(14, status='delete')
	EXIT
	end if
	nlines=nlines+1
	chainprev(1:1)=chain(1:1)
	end do
	stop=nlines
	nr=stop-start

	write(*,*)start,stop,nr,nlines
	close(13)
	close(23)

!	nc=nc-1
!	open(unit=1,file="ncopies.dat")
!	write(1,*)nc
!	close(1)

	end program
