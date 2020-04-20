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
exec [dbo].[mspRefreshARAging] @Company, @Month,@OverrideARClose
