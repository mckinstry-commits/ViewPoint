use Viewpoint
go


declare cmcur cursor for
select
	cmac.CMCo
,	cmac.CMAcct
from 
	CMAC cmac
where cmac.CMCo<100
order by 1,2
for read only

declare @retTabe table
(
	CMCo bCompany
,	CMAcct bCMAcct
,	nextCheck	bigint
,	msg varchar(255)
)

declare @CMCo bCompany
declare @CMAcct bCMAcct
declare @nextCheck	bigint
declare @msg varchar(255)

	print
		cast('CMCo' as char(8))
	+	cast('CMAcct' as char(8))
	+	cast('Next Check' as char(20))
	+	'System Message'

	print replicate('-',100)

open cmcur
fetch cmcur into @CMCo, @CMAcct

while @@FETCH_STATUS=0
begin

	exec bspAPBeginCheckDflt @cmco=@CMCo,@cmacct=@CMAcct,@begcheck=@nextCheck output,@msg=@msg output

	insert @retTabe (CMCo,CMAcct,nextCheck,msg)
	values (@CMCo, @CMAcct, @nextCheck, @msg)

	print
		cast(@CMCo as char(8))
	+	cast(@CMAcct as char(8))
	+	cast(@nextCheck as char(20))
	+	@msg

	fetch cmcur into @CMCo, @CMAcct
end

close cmcur
deallocate cmcur

select * from @retTabe
go

