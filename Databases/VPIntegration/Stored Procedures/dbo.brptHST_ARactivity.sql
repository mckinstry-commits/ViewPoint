SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer - Tailored to GST/PST/HST by DML - 15 April 2010
-- Create date: 4/10/09
-- Description:	GST activity Stmt AR
-- Issue # 
-- =============================================
CREATE PROCEDURE [dbo].[brptHST_ARactivity]
	@GTSTaxCode varchar(12), @ExportSales varchar (12), @GTStxFree varchar(12), 
	 @ARCo  bCompany,
	@BeginDate bDate, @EndDate bDate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--


declare @MyGSTTaxRate as decimal(9,8)
select @MyGSTTaxRate = NewRate from HQTX where TaxCode = @GTSTaxCode


--
--Declare @GTSTaxCode varchar(12) 
--set @GTSTaxCode = 'GSTs'
--
--Declare @ExportSales varchar (12)
--set @ExportSales = 'GSTExport'
-- 
--Declare @GTStxFree varchar(12) 
--set @GTStxFree = 'GSTfree'
--
--Declare @ARCo  bCompany
--set @ARCo = '1'
--
--Declare @BeginDate bDate 
--set @BeginDate = '1950-01-01'
--
--Declare @EndDate bDate
--set @EndDate = '2050-12-31'


Declare @GSTInvoiceList table
(Invoice varchar (10))

--insert @GSTInvoiceList values ('     10074') 
--insert @GSTInvoiceList values ('     10078') 

insert @GSTInvoiceList
select distinct TH.Invoice from 
					ARTH TH
					join ARTL TL
						on TH.ARCo = TL.ARCo
						and TH.Mth = TL.Mth
						and TH.ARTrans = TL.ARTrans
					where (TaxCode = @GTSTaxCode
							or TaxCode = @ExportSales
							or TaxCode =  @GTStxFree)
					and Invoice is not Null	
					and TH.ARCo = @ARCo
					and(TH.TransDate >= @BeginDate and TH.TransDate <= @EndDate)
	
		

--select * from @GSTInvoiceList

select
Customer,
Invoice,
sum(Amount) as 'Amount',
sum([Retention]) as 'Retention',
sum(RetentionBilled) as 'RetentionBilled',
sum(BASbasis) as 'BASbasis',
sum(GSTCalculated) as 'GSTCalculated',
SalesType,
GSTSort
from (
SELECT 
(select Name from ARCM where Customer = ARTH.Customer and CustGroup = ARTH.CustGroup) as 'Customer',
LTrim(RTrim(ARTH.Invoice)) As 'Invoice',
--isnull(ARTL.TaxBasis,0) as 'Amount',
--isnull((ARTL.Amount - ARTL.TaxAmount),0) as 'Amount',  
isnull(ARTL.TaxBasis,0) + isnull(ARTL.Retainage,0) - isnull(ARTL.RetgTax,0) as 'Amount',  
isnull(ARTL.Retainage, 0) - isnull(ARTL.RetgTax,0) as 'Retention',
0 as 'RetentionBilled',
isnull(ARTL.Amount, 0) - isnull(ARTL.TaxAmount,0)- isnull(ARTL.Retainage,0) as 'BASbasis',
(isnull(ARTL.Amount,0) - isnull(ARTL.TaxAmount,0)- isnull(ARTL.Retainage,0)) * isnull(@MyGSTTaxRate,0)  as 'GSTCalculated',
--ARTH.ARTransType,
case ARTL.TaxCode
when @GTSTaxCode then 'Total sales G1'
when @ExportSales then 'Export sales G2'
when @GTStxFree then 'Other GST-free sales G3'
else 'Other' end as 'SalesType',

case ARTL.TaxCode
when @GTSTaxCode then 1
when @ExportSales then 2
when @GTStxFree then 3
else 4 end as 'GSTSort'
from ARTH
join ARTL ARTL 
	ON ARTL.ARCo=ARTH.ARCo 
	AND ARTL.Mth=ARTH.Mth 
	AND ARTL.ARTrans=ARTH.ARTrans 
WHERE  
(ARTL.TaxCode = @GTSTaxCode
or ARTL.TaxCode = @ExportSales
or ARTL.TaxCode =  @GTStxFree)
and ARTL.ARCo=@ARCo
and ARTH.ARTransType = 'I'
and ARTH.Invoice in (select Invoice from @GSTInvoiceList)

Union All

SELECT 
(select Name from ARCM where Customer = ARTH.Customer and CustGroup = ARTH.CustGroup) as 'Customer',
LTrim(RTrim(ARTH.Invoice)) As 'Invoice',
0 as 'Amount', 
ARTL.Retainage as 'Retention',
isnull(ARTL.Amount,0) - isnull(ARTL.TaxAmount,0) as 'RetentionBilled',
isnull(ARTL.Amount,0) - isnull (ARTL.TaxAmount,0) as 'BASbasis',
(isnull(ARTL.Amount,0) - isnull(ARTL.TaxAmount,0))* isnull(@MyGSTTaxRate,0)  as 'GSTCalculated',
--ARTH.ARTransType,
case ARTL.TaxCode
when @GTSTaxCode then 'Total sales G1'
when @ExportSales then 'Export sales G2'
when @GTStxFree then 'Other GST-free sales G3'
else 'Other' end as 'SalesType',

case ARTL.TaxCode
when @GTSTaxCode then 1
when @ExportSales then 2
when @GTStxFree then 3
else 4 end as 'GSTSort'
FROM   
ARTL ARTL 
INNER JOIN HQCO HQCO 
	ON ARTL.ARCo=HQCO.HQCo 
LEFT OUTER JOIN ARTH ARTH 
	ON ARTL.ARCo=ARTH.ARCo 
	AND ARTL.Mth=ARTH.Mth 
	AND ARTL.ARTrans=ARTH.ARTrans 
WHERE  
(ARTL.TaxCode = @GTSTaxCode
or ARTL.TaxCode = @ExportSales
or ARTL.TaxCode =  @GTStxFree)
and ARTL.ARCo=@ARCo 
and ARTH.ARTransType = 'R'
and ARTH.Invoice in (select Invoice from @GSTInvoiceList) )as T
group by
Customer,
Invoice,
SalesType,
GSTSort


End


GO
GRANT EXECUTE ON  [dbo].[brptHST_ARactivity] TO [public]
GO
