use Viewpoint
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspRefreshARAgingAll' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE')
begin
	print 'DROP PROCEDURE [dbo].[mspRefreshARAgingAll]'
	DROP PROCEDURE [dbo].[mspRefreshARAgingAll]
end
go

print 'CREATE PROCEDURE [dbo].[mspRefreshARAgingAll]'
go

create procedure mspRefreshARAgingAll
(
	@Company	tinyint	= null
,	@Simulate	bit = 0
)
as
/*
mspRefreshARAgingAll

2015.09.11 - LWO - Changed to use LastMthGLClsd instead of LastMthARClsd to support the
                   inclusion of adjustments after AR closes but only until the GL itself 
				   is closed.
*/

declare arcocur cursor for
select 

	arco.ARCo, glco.LastMthGLClsd --  glco.LastMthARClsd 
from 
	ARCO arco join 
	GLCO glco on 
		arco.GLCo=glco.GLCo
where
	(arco.ARCo=@Company or @Company is null)
order by 1

declare @curCo tinyint
declare @lastClosedMonth smalldatetime

declare @monthToProcess smalldatetime

declare @msg varchar(255)

open arcocur
fetch arcocur into
	@curCo 
,	@lastClosedMonth 

while @@fetch_status=0
begin
	select @monthToProcess = dateadd(month,1,@lastClosedMonth)

	while @monthToProcess <= cast(cast(MONTH(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4)) as smalldatetime)
	begin
		print cast(@curCo as char(5)) +  convert(varchar(10),@monthToProcess,101)
		
		if @Simulate<>0 
			print replicate(' ',5) + 'exec [dbo].[mspRefreshARAging] @Company=' + cast(@curCo as varchar(10)) + ',@MonthToProcess=''' +  convert(varchar(10),@monthToProcess,101) + ''',@OverrideARClose=0'
		else
			exec [dbo].[mspRefreshARAging]  @Company=@curCo, @MonthToProcess=@monthToProcess, @OverrideARClose=0
		
		print ''

		select @monthToProcess = dateadd(month,1,@monthToProcess)

		
	end
	
	select 	
		@curCo = null
	,	@lastClosedMonth = null
	,	@monthToProcess = null

	fetch arcocur into
		@curCo 
	,	@lastClosedMonth 

end

close arcocur
deallocate arcocur
go

print 'GRANT EXECUTE RIGHTS TO [public, Viewpoint]'
print ''
go

grant exec on [dbo].[mspRefreshARAgingAll] to public
go

--grant exec on [dbo].[mspRefreshARAgingAll] to Viewpoint
--go

/*
1    08/01/2015
     exec [dbo].[mspRefreshARAging] @Company=1,@MonthToProcess='08/01/2015',@OverrideARClose=0
 
1    09/01/2015
     exec [dbo].[mspRefreshARAging] @Company=1,@MonthToProcess='09/01/2015',@OverrideARClose=0
 
20   08/01/2015
     exec [dbo].[mspRefreshARAging] @Company=20,@MonthToProcess='08/01/2015',@OverrideARClose=0
 
20   09/01/2015
     exec [dbo].[mspRefreshARAging] @Company=20,@MonthToProcess='09/01/2015',@OverrideARClose=0
 
60   08/01/2015
     exec [dbo].[mspRefreshARAging] @Company=60,@MonthToProcess='08/01/2015',@OverrideARClose=0
 
60   09/01/2015
     exec [dbo].[mspRefreshARAging] @Company=60,@MonthToProcess='09/01/2015',@OverrideARClose=0
 
222  07/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='07/01/2014',@OverrideARClose=0
 
222  08/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='08/01/2014',@OverrideARClose=0
 
222  09/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='09/01/2014',@OverrideARClose=0
 
222  10/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='10/01/2014',@OverrideARClose=0
 
222  11/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='11/01/2014',@OverrideARClose=0
 
222  12/01/2014
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='12/01/2014',@OverrideARClose=0
 
222  01/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='01/01/2015',@OverrideARClose=0
 
222  02/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='02/01/2015',@OverrideARClose=0
 
222  03/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='03/01/2015',@OverrideARClose=0
 
222  04/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='04/01/2015',@OverrideARClose=0
 
222  05/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='05/01/2015',@OverrideARClose=0
 
222  06/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='06/01/2015',@OverrideARClose=0
 
222  07/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='07/01/2015',@OverrideARClose=0
 
222  08/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='08/01/2015',@OverrideARClose=0
 
222  09/01/2015
     exec [dbo].[mspRefreshARAging] @Company=222,@MonthToProcess='09/01/2015',@OverrideARClose=0
 

exec mspRefreshARAgingAll @Company=1, @Simulate=1
exec mspRefreshARAgingAll @Company=20, @Simulate=1
*/



exec [dbo].[mspRefreshARAging] @Company=null,@MonthToProcess='5/1/2015',@OverrideARClose=1
exec [dbo].[mspRefreshARAging] @Company=null,@MonthToProcess='6/1/2015',@OverrideARClose=1
