use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetARTranHistory' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnGetARTranHistory]'
	drop function [dbo].[mfnGetARTranHistory] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnGetARTranHistory]'
go


CREATE FUNCTION [dbo].[mfnGetARTranHistory] 
(
	@CustGroup	tinyint
,	@Customer	int
,	@Invoice	varchar(10)
)  
RETURNS varchar(max)
AS  
BEGIN 

declare @retStr varchar(max)
declare @tmpStr varchar(max)

select @retStr = ''

declare cncur cursor for
with ari as
(
Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL     
                            Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans    
                            where ARTH.CustGroup=@CustGroup and ARTH.Customer=@Customer and ARTH.Invoice=@Invoice
							Group By ARTL.ARCo, ApplyMth, ApplyTrans --having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0    
)
select 
	'[' + cast(convert(varchar(10),arth.TransDate,101) + ' ' +
	'(' + arth.ARTransType + ') ' as char(15)) +
	'$ ' + cast(artl.Amount as varchar(20)) + ' ] ' +
	case  arth.ARTransType when 'P' then convert(varchar(10),arth.CheckDate,101) + ' : CK# ' + arth.CheckNo else '' end +
	+ CHAR(13) + + CHAR(10)
from 
	ari t1
join ARTL artl on
	artl.ApplyTrans=t1.ApplyTrans 
and artl.ARCo=t1.ARCo
and artl.ApplyMth=t1.ApplyMth
join ARTH arth on 
	artl.ARCo=arth.ARCo 
and artl.Mth=arth.Mth 
and artl.ARTrans = arth.ARTrans 
order by
	arth.TransDate 
,	arth.ARTrans 
for read only

open cncur
fetch cncur into @tmpStr

while @@FETCH_STATUS=0
begin
	--print @tmpStr
	select @retStr = @retStr + @tmpStr + CHAR(13) + + CHAR(10)

	fetch cncur into @tmpStr
end

close cncur
deallocate cncur

return @retStr

end


GO

print 'GRANT SELECT ON [dbo].[mfnGetARTranHistory] TO [public, Viewpoint]'
print ''
go

grant exec on [dbo].[mfnGetARTranHistory] to public
go

--grant exec on [dbo].[mfnGetARTranHistory] to Viewpoint
go
