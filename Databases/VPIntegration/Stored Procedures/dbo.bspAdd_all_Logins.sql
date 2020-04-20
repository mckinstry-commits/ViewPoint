SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure dbo.bspAdd_all_Logins as 
begin
declare @name as varchar(30), @sqlcmd as varchar(250)

declare bcsyslogins cursor for 
Select  name from master..syslogins where 
name not in (select name from sysusers) and name not like '##%' and name not like '%SQLServer%'
 and name <> 'sa'
 
open bcsyslogins
Fetch next from bcsyslogins into @name
while @@fetch_status = 0
begin
	select @name = '['+@name+']' 
print @name
set @sqlcmd =''
set @sqlcmd =  'CREATE USER '+@name 
exec(@sqlcmd)
 
Fetch next from bcsyslogins into @name 
End
Close bcsyslogins
Deallocate bcsyslogins
end
GO
GRANT EXECUTE ON  [dbo].[bspAdd_all_Logins] TO [public]
GO
