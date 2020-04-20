SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer - Tailored to GST/PST/HST by DML - 15 April 2010
-- Create date: 4/9/09
-- Description:	GST AP section
-- =============================================
CREATE PROCEDURE [dbo].[brptHST_APactivity]
		@GTStxCap varchar(12), @GTStxNCap varchar(12), 
		@APCo  bCompany,
		@BeginDate bDate, @EndDate bDate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @GTStxCap varchar(12)
--set @GTStxCap = 'GSTp'
--
--declare @GTStxNCap varchar(12)
--set @GTStxNCap = 'GSTpnc'
--
--declare @APCo bCompany
--set @APCo = 1
--
--declare @BeginDate bDate
--set @BeginDate = '06-01-2008'
--
--declare @EndDate bDate
--set @EndDate = '06-30-2009'


Declare @GSTInvoiceList table
(Invoice varchar (15))

insert @GSTInvoiceList --values ('     50505') 
select distinct APRef from APTH TH
join APTL TL
	on TH.APCo=TL.APCo 
	AND TH.Mth=TL.Mth 
	AND TH.APTrans=TL.APTrans
where (TaxCode = @GTStxCap
	or TaxCode = @GTStxNCap )
	and(TH.InvDate >= @BeginDate and TH.InvDate <= @EndDate)
	and TL.APCo = @APCo

--select * from @GSTInvoiceList

select 
Vendor,
VendorName,
Invoice,
InvoiceDate,
AccountingMth,
GLAcct,
TaxCode,
PurchaseType,
GSTSort,
sum(Amount) as 'Amount',
max(GSTTaxRate) as 'GSTTaxRate',
sum(Tax) as 'Tax',
sum(Retention) as 'Retention',
sum(GSTonRetention) as 'GSTonRetention',
sum(Total) as 'Total'
from


(select
--'RetainageLine',
CAST(TH.Vendor AS varchar(6))
 + ' - ' + 
(select [Name] from APVM where Vendor = TH.Vendor and VendorGroup = TH.VendorGroup) as 'Vendor', 
(select [Name] from APVM where Vendor = TH.Vendor and VendorGroup = TH.VendorGroup) as 'VendorName', 
TH.APRef as 'Invoice',
TH.InvDate as 'InvoiceDate', 
TH.Mth as 'AccountingMth', 
TL.GLAcct as 'GLAcct',
TL.TaxCode as 'TaxCode', 
case TL.TaxCode
when @GTStxCap then 'Capital Purchases'
when @GTStxNCap then 'Non Capital Purchases'
else 'Non GST' end as 'PurchaseType',

case TL.TaxCode
when @GTStxCap then 1
when @GTStxNCap then 2
else 3 end as 'GSTSort',
----------------------------------------
case when TD.Status = 2 then 0 else TL.Retainage end as 'Amount',
isnull(TX.NewRate, 0) as 'GSTTaxRate',
case when TD.Status = 2 then 0 	else TL.Retainage * TX.NewRate end as 'Tax',
case when TD.Status = 2 then TL.Retainage else 0 end as 'Retention',
case when TD.Status = 2 then TL.Retainage * TX.NewRate else 0 end as 'GSTonRetention',

isnull(TL.Retainage  + (TL.Retainage * TX.NewRate), 0)  as 'Total'
from
APTH TH
join APTL TL
	on TH.APCo=TL.APCo 
	AND TH.Mth=TL.Mth 
	AND TH.APTrans=TL.APTrans 
join APTD TD
	on TL.APCo=TD.APCo 
	AND TL.Mth=TD.Mth 
	AND TL.APTrans=TD.APTrans 
	AND TL.APLine=TD.APLine
join HQTX TX
	on TL.TaxCode = TX.TaxCode
	and TL.TaxGroup = TX.TaxGroup
join APCO APCO
	on TH.APCo = APCO.APCo
where 
TD.PayType = APCO.RetPayType
and TH.APRef in (select Invoice from @GSTInvoiceList)
and TL.TaxCode in (@GTStxCap, @GTStxNCap)

Union All

select
--'NonRetainAmount',
CAST(TH.Vendor AS varchar(6))
 + ' - ' + 
(select [Name] from APVM where Vendor = TH.Vendor and VendorGroup = TH.VendorGroup) as 'Vendor', 
(select [Name] from APVM where Vendor = TH.Vendor and VendorGroup = TH.VendorGroup) as 'VendorName', 
TH.APRef as 'Invoice',
TH.InvDate as 'InvoiceDate', 
TH.Mth as 'AccountingMth', 
TL.GLAcct as 'GLAcct',
TL.TaxCode, 
case TL.TaxCode
when @GTStxCap then 'Capital Purchases'
when @GTStxNCap then 'Non Capital Purchases'
else 'Non GST' end as 'PurchaseType',
case TL.TaxCode
when @GTStxCap then 1
when @GTStxNCap then 2
else 3 end as 'GSTSort',
TL.TaxBasis - TL.Retainage as 'Amount',
isnull(TX.NewRate, 0) as 'GSTTaxRate',
(TL.TaxBasis - TL.Retainage) * TX.NewRate as 'Tax',
0 as 'Retention',
0 as 'GSTonRetention',
(TL.TaxBasis - TL.Retainage)* (1 + TX.NewRate) as 'Total'
from
APTH TH
join APTL TL
	on TH.APCo=TL.APCo 
	AND TH.Mth=TL.Mth 
	AND TH.APTrans=TL.APTrans 
join APTD TD
	on TL.APCo=TD.APCo 
	AND TL.Mth=TD.Mth 
	AND TL.APTrans=TD.APTrans 
	AND TL.APLine=TD.APLine
join HQTX TX
	on TL.TaxCode = TX.TaxCode
	and TL.TaxGroup = TX.TaxGroup
join APCO APCO
	on TH.APCo = APCO.APCo
where 
TD.PayType <> APCO.RetPayType
and TH.APRef in (select Invoice from @GSTInvoiceList)
and TL.TaxCode in (@GTStxCap, @GTStxNCap)

) as X
group by 
Vendor,
VendorName,
Invoice,
InvoiceDate,
AccountingMth,
GLAcct,
TaxCode,
PurchaseType,
GSTSort

End

GO
GRANT EXECUTE ON  [dbo].[brptHST_APactivity] TO [public]
GO
