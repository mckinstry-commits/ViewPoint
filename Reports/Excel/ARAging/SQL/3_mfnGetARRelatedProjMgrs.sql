use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetARRelatedProjMgrs' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnGetARRelatedProjMgrs]'
	drop function [dbo].[mfnGetARRelatedProjMgrs] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnGetARRelatedProjMgrs]'
go

CREATE FUNCTION [dbo].[mfnGetARRelatedProjMgrs] 
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
Select distinct
/* ARTL.ARCo, ApplyMth, ApplyTrans, ARTL.JCCo, ARTL.Contract, ARTL.Item, JCJM.Job, JCJM.ProjectMgr, */ JCMP.Name
From ARTL     
Join ARTH on 
	ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans  
join JCJM on
	ARTL.JCCo=JCJM.JCCo and ARTL.Contract=JCJM.Contract 
join JCMP on
	JCJM.JCCo=JCMP.JCCo and JCJM.ProjectMgr=JCMP.ProjectMgr
where ARTH.CustGroup=@CustGroup and ARTH.Customer=@Customer and ARTH.Invoice=@Invoice
for read only

open cncur
fetch cncur into @tmpStr

while @@FETCH_STATUS=0
begin
	--print @tmpStr
	select @retStr = @retStr + @tmpStr + '; ' + CHAR(13) + + CHAR(10)

	fetch cncur into @tmpStr
end

close cncur
deallocate cncur

return @retStr

end


GO

print 'GRANT SELECT ON [dbo].[mfnGetARRelatedProjMgrs] TO [public, Viewpoint]'
print ''
go

grant exec on [dbo].[mfnGetARRelatedProjMgrs] to public
go

--grant exec on [dbo].[mfnGetARRelatedProjMgrs] to Viewpoint
go
