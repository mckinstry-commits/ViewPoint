use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnARAgingSummary' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnARAgingSummary]'
	DROP FUNCTION [dbo].[mfnARAgingSummary]
end
go

print 'CREATE FUNCTION [dbo].[mfnARAgingSummary]'
go

create function mfnARAgingSummary
(
	@FinancialPeriod smalldatetime
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnARAgingSummary                                                                                     *
*                                                                                                   *
* ** Do not run with null Contract, query will not come back                                        *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 03/07/2014   BillO          Created                                                               *
* 03/13/2014   ZachF          Added Derived columns                                                 *
*                                                                                                   *
*                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
RETURN

----Create Function mfnARAgingSummary
----Summary Pivot
with sumtbl as
(select FinancialPeriod,ARCo, Customer, InvoiceContract, Invoice, ApplyMth, ApplyTrans, GLDepartmentNumber,GLDepartmentName,  sum(case when ARTransType<>'P' then coalesce(Amount,0) else 0 end) as Invoiced, sum(Retainage) as Retainage, sum(case when ARTransType='P' then coalesce(Paid,0) else 0 end) as Paid, sum(TaxAmount) as TaxAmount, max(CheckDate) as LastPaymentDate from [dbo].[budARAgingHistory] where (FinancialPeriod=@FinancialPeriod or @FinancialPeriod is null) group by FinancialPeriod,ARCo, Customer, InvoiceContract, Invoice, ApplyMth, ApplyTrans, GLDepartmentNumber,GLDepartmentName)
select 
	pvt.*
,	t1.Invoiced
,	t1.Retainage
,	t1.Paid
,	t1.TaxAmount
,	t1.LastPaymentDate
from
(
	select * from 
	(
		select 
				[FinancialPeriod]
			,	[ARCo]
			,	CustomerName = [Name]
			,	[CustGroup]
			,	[Customer]
			,	[InvoiceContract]
			,	CustomerPhone = [Phone]
			,	CustomerContact = [Contact]
			,	[GLDepartmentNumber]
			,	[GLDepartmentName]
			--,	InvoiceJCCo
			--,	InvoiceContract
			--,	InvoiceSMCo
			--,	InvoiceSMWorkOrder
			,	coalesce([Invoice],'Unapplied') as Invoice
			,	[InvoiceTransDate]
			,	[InvoiceDueDate]
			,	[InvoiceDesc]
			,	[CollectionNotes]
			,	[InvoiceTermsCode]
			,	[InvoiceTerms]
			,	[ContractTermsCode]
			,	[ContractTerms]
			,	[AgeAmount]
			,	[AgeBucket]
			,	[AgeDate]
			,	[DaysFromAge]
			,	[ApplyMth]
			,	[ApplyTrans]
			,	TransactionHistory
			,	ProjectManagers
		from 
			[dbo].[budARAgingHistory]
		where
			(FinancialPeriod=@FinancialPeriod or @FinancialPeriod is null)
	) DataTable
	PIVOT
	(
		SUM([AgeAmount])
		for [AgeBucket]
		in ([Current],[Aged1to30],[Aged31to60],[Aged61to90],[AgedOver90])
	) PivotTable
) pvt 
left JOIN sumtbl t1  on
	t1.FinancialPeriod=pvt.FinancialPeriod
and	t1.ARCo=pvt.ARCo
and t1.Customer=pvt.Customer
and t1.Invoice=pvt.Invoice
and t1.GLDepartmentNumber=pvt.GLDepartmentNumber
and t1.InvoiceContract=pvt.InvoiceContract
and t1.ApplyMth=pvt.ApplyMth
and t1.ApplyTrans=pvt.ApplyTrans
--order by t1.Invoice
go

print 'GRANT EXECUTE RIGHTS TO [public, Viewpoint]'
print ''
go

grant select on [dbo].[mfnARAgingSummary] to public
go

grant select on [dbo].[mfnARAgingSummary] to Viewpoint
go
