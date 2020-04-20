use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

declare @Company				bCompany
declare @Month					bMonth
declare @OverrideARClose		tinyint

set @Company					= null
set @OverrideARClose=0
set @Month						= cast(cast(month(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4))) as smalldatetime)

select * from [dbo].[mfnARAgingDetail](@Month)

select *,(coalesce([Current],0)+coalesce(Aged1to30,0)+coalesce(Aged31to60,0)+coalesce(Aged61to90,0)+coalesce(AgedOver90,0)) as TotalAged from [dbo].[mfnARAgingSummary]('08/1/2015') where 1=1

