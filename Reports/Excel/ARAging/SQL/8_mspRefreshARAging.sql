use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspRefreshARAging' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE')
begin
	print 'DROP PROCEDURE [dbo].[mspRefreshARAging]'
	DROP PROCEDURE [dbo].[mspRefreshARAging]
end
go

print 'CREATE PROCEDURE [dbo].[mspRefreshARAging]'
go

create procedure [dbo].[mspRefreshARAging]
(
	@Company tinyint = null
,	@MonthToProcess smalldatetime
,	@OverrideARClose tinyint = 0
)
as

if @MonthToProcess is null
begin
	select @MonthToProcess = cast(cast(MONTH(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4)) as smalldatetime)
	--select @MonthToProcess = dateadd(month,-1,cast(cast(MONTH(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4)) as smalldatetime))
end

--Get Last Closed AR Period
create table #ClosedARPeriods
(
	ARCo   tinyint  null,    
	LastMthARClsd	smalldatetime
)

insert into #ClosedARPeriods
select GLCo, LastMthARClsd 
from GLCO
where
	GLCo = @Company or @Company is null
order by 1

declare @curCo tinyint
declare @lastClosedMonth smalldatetime
declare @msg varchar(255)

declare cpcur cursor for select ARCo, LastMthARClsd from #ClosedARPeriods order by 1 for read only
open cpcur

fetch cpcur into @curCo,@lastClosedMonth
while @@fetch_status=0

begin
	if @lastClosedMonth < @MonthToProcess or @OverrideARClose <> 0
	begin
		select @msg = cast(@curCo as varchar(10)) + ' : ' + convert(varchar(10),@MonthToProcess, 110)
		print 'Refreshing AR Aging for ' + @msg

		delete [dbo].[budARAgingHistory] where [ARCo]=@curCo and [FinancialPeriod]=@MonthToProcess

		--declare @Company				bCompany
		declare @Month					bMonth 
		declare @AgeDate				bDate 
		declare @BegCust				bCustomer
		declare @EndCust				bCustomer
		declare @RecType				varchar(20) 
		declare @IncludeInvoicesThrough bDate 
		declare @IncludeAdjPayThrough	bDate 
		declare @AgeOnDueorInv			char(1)
		declare @LevelofDetail			char(1)
		declare @DeductDisc				char(1)
		declare @DaysBetweenCols		tinyint
		declare @AgeOpenCredits			char(1)
		declare @BegPM					int
		declare @EndPM					int
		declare @BegContract			bContract 
		declare @EndContract			bContract 
		declare @BegGLDepartment		varchar(10) 
		declare @EndGLDepartment		varchar(10) 
		declare @SummaryOrDetail		char(1) 

		set @Company					= @curCo
		set @Month						= @MonthToProcess
		set @AgeDate					= null
		set @BegCust					=0
		set @EndCust					=999999
		set @RecType					=	''
		set @IncludeInvoicesThrough		= '12/31/2049'
		set @IncludeAdjPayThrough		= '12/31/2049'
		set @AgeOnDueorInv				='D'
		set @LevelofDetail				='I'
		set @DeductDisc					='Y'
		set @DaysBetweenCols			=30
		set @AgeOpenCredits				='N'
		set @BegPM						=0
		set @EndPM						=2147483647
		set @BegContract				= ''
		set @EndContract				= 'zzzzzzzzzz'
		set @BegGLDepartment			= null
		set @EndGLDepartment			= null
		set @SummaryOrDetail			= 'D'

		exec [dbo].[mspARAgeCustCont]   
			@Company 
		,	@Month 
		,	@AgeDate 
		,	@BegCust 
		,	@EndCust 
		,	@RecType  
		,	@IncludeInvoicesThrough  
		,	@IncludeAdjPayThrough  
		,	@AgeOnDueorInv
		,	@LevelofDetail 
		,	@DeductDisc
		,	@DaysBetweenCols 
		,	@AgeOpenCredits
		,	@BegPM 
		,	@EndPM 
		,	@BegContract 
		,	@EndContract 
		,	@BegGLDepartment 
		,	@EndGLDepartment 
		,	@SummaryOrDetail 
		,	@DoRefresh=1
	end
	else
	begin
		select @msg = cast(@curCo as varchar(10)) + ' : ' + convert(varchar(10),@MonthToProcess, 110)
		print 'AR Aging Cannot be Refreshed for a Closed AR Period [' + @msg + ']'
	end

	fetch cpcur into @curCo,@lastClosedMonth

end

close cpcur
deallocate cpcur

go

print 'GRANT EXECUTE RIGHTS TO [public, Viewpoint]'
print ''
go

grant exec on [dbo].[mspRefreshARAging] to public
go

grant exec on [dbo].[mspRefreshARAging] to Viewpoint
go
