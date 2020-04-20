use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='mvwARCollectionSummary' and TABLE_SCHEMA='dbo' and TABLE_TYPE='VIEW')
begin
	print 'DROP VIEW [dbo].[mvwARCollectionSummary]'
	DROP VIEW [dbo].[mvwARCollectionSummary]
end
go

print 'CREATE VIEW [dbo].[mvwARCollectionSummary]'
go

create view mvwARCollectionSummary

AS
/****************************************************************************************************
* mfnARCollectionSummary                                                                                     *
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

select
--	FinancialPeriod	
	ARCo	
,	GLDepartmentNumber	
,	GLDepartmentName	
,	CustomerName	
,	Customer	
--,	CustGroup	
,	InvoiceTermsCode	
,	Invoice	
,	InvoiceContract	
,	InvoiceDesc
,	POCName
,	InvoiceTransDate	
,	InvoiceDueDate	
,	Invoiced	
,	Retainage	
,	DaysFromAge	
,	coalesce([Current],0)
+	coalesce(Aged1to30,0)	
+	coalesce(Aged31to60,0)	
+	coalesce(Aged61to90,0)	
+	coalesce(AgedOver90,0)	as TotalAged
,	coalesce([Current],0) as [Current]
,	coalesce(Aged1to30,0) as Aged1to30
,	coalesce(Aged31to60,0) as Aged31to60	
,	coalesce(Aged61to90,0) as Aged61to90	
,	coalesce(AgedOver90,0) as AgedOver90	
,	coalesce(Paid,0) as Paid	
,	LastPaymentDate
,	CollectionNotes	
--,	CustomerPhone	
--,	CustomerContact	
--,	InvoiceDesc	
--,	InvoiceTerms	
--,	ContractTermsCode	
--,	ContractTerms	
--,	AgeDate	
--,	ApplyMth	
--,	ApplyTrans	
--,	TransactionHistory	
--,	ProjectManagers	

--,	TaxAmount	
from
	dbo.mfnARAgingSummary(cast(cast(month(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4)) as smalldatetime)	)
--order by t1.Invoice
go

print 'GRANT select RIGHTS TO mvwARCollectionSummary [public, Viewpoint]'
print ''
go

grant select on [dbo].[mvwARCollectionSummary] to public
go

grant select on [dbo].[mvwARCollectionSummary] to Viewpoint
go


select * from [mvwARCollectionSummary]