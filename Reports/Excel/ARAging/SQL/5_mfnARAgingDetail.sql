use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnARAgingDetail' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnARAgingDetail]'
	DROP FUNCTION [dbo].[mfnARAgingDetail]
end
go

print 'CREATE FUNCTION [dbo].[mfnARAgingDetail]'
go

create function mfnARAgingDetail
(
	@FinancialPeriod smalldatetime
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnARAgingDetail                                                                                     *
*                                                                                                   *
* ** Do not run with null Contract, query will not come back                                        *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 08/04/2014   BillO          Created                                                               *
*                                                                                                   *
*                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
RETURN
select
	*
from 
	[dbo].[budARAgingHistory]
where
	(FinancialPeriod=@FinancialPeriod or @FinancialPeriod is null)
go

print 'GRANT EXECUTE RIGHTS TO [public, Viewpoint]'
print ''
go

grant select on [dbo].[mfnARAgingDetail] to public
go

grant select on [dbo].[mfnARAgingDetail] to Viewpoint
go
