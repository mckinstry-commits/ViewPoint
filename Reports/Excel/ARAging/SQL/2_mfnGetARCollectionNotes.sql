use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetARCollectionNotes' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnGetARCollectionNotes]'
	drop function [dbo].[mfnGetARCollectionNotes] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnGetARCollectionNotes]'
go

CREATE FUNCTION [dbo].[mfnGetARCollectionNotes] 
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
select '[' + convert(varchar(10),Date,101) + ' ' + UserID + '(' + cast(Seq as varchar(10)) + ')' + '] - ' + Notes 
from 
	ARCN 
where 
	Invoice is not null 
and Notes is not null 
and CustGroup=@CustGroup --1
and Customer=@Customer --206341
and Invoice=@Invoice --7880
--and 
order by 
	Invoice,Date desc
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

print 'GRANT SELECT ON [dbo].[mfnGetARCollectionNotes] TO [public, Viewpoint]'
print ''
go

grant exec on [dbo].[mfnGetARCollectionNotes] to public
go

--Permission for 6.10+ Environment
--grant exec on [dbo].[mfnGetARCollectionNotes] to Viewpoint
go
