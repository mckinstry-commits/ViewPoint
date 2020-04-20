use Viewpoint
go

if exists (select 1 from sysobjects where name='mspAddStandardPMUser' and type='P')
begin
	drop procedure mspAddStandardPMUser
end
go

CREATE procedure mspAddStandardPMUser
(
	@email	varchar(50)
)
as

set nocount on


declare @rcode int
declare @msg varchar(255)
exec @rcode = mckspAddADUsers 'ViewpointUsers',1,@msg OUTPUT
select @msg

if @rcode < 0
begin
	print 'Unable to add user.'
	return -1
end

declare uccur cursor for
select VPUserName,vDDUP.EMail from vDDUP where lower(vDDUP.EMail) = lower(@email)
for read only

declare @vpu varchar(30)
declare @vpe varchar(70)
declare @PRCo bCompany
declare @Employee bEmployee

open uccur
fetch uccur into @vpu,@vpe

while @@fetch_status=0
begin

	select
		@PRCo=cast(c.COMPANYREFNO as int)
	,	@Employee=cast(p.REFERENCENUMBER as int)
	from 
		SESQL08.HRNET.dbo.PEOPLE p join 
		SESQL08.HRNET.dbo.JOBDETAIL jd on p.PEOPLE_ID=jd.PEOPLE_ID and jd.TOPJOB='T' and jd.CURRENTRECORD='YES' JOIN 
		SESQL08.HRNET.dbo.COMPANY c on jd.COMPANY=c.COMPANY_ID 
	where 
		p.STATUS='A' 
	and lower(EMAILPRIMARY)=lower(@vpe)

	update DDUP set PRCo=@PRCo, Employee=@Employee where VPUserName=@vpu and ( PRCo is null or Employee is null )

	if not exists ( select 1 from DDSU where VPUserName=@vpu and SecurityGroup=2)
	begin
		insert DDSU ( SecurityGroup, VPUserName) values ( 2, @vpu )
		print @vpu + ' : 2'
	end

	if not exists ( select 1 from DDSU where VPUserName=@vpu and SecurityGroup=4)
	begin
		insert DDSU ( SecurityGroup, VPUserName) values ( 4, @vpu )
		print @vpu + ' : 4'
	end

	if not exists ( select 1 from DDSU where VPUserName=@vpu and SecurityGroup=201)
	begin
		insert DDSU ( SecurityGroup, VPUserName) values ( 201, @vpu )
		print @vpu + ' : 201'
	end

	if not exists ( select 1 from DDSU where VPUserName=@vpu and SecurityGroup=10000)
	begin
		insert DDSU ( SecurityGroup, VPUserName) values ( 10000, @vpu )
		print @vpu + ' : 10000'
	end

	fetch uccur into @vpu,@vpe
end

close uccur
deallocate uccur
go

--mspAddStandardPMUser 'jakes@mckinstry.com'