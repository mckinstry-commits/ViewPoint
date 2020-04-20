SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/9/09
-- Description:	GST AP section
-- =============================================
CREATE PROCEDURE [dbo].[brptGST_Main]

@ARCo  bCompany, --AR Tax accounts
@GTSTaxCode varchar(12),
@ExportSales varchar (12), 
@GTStxFree varchar(12),
@APCo bCompany,--AP tax accounts
@GTStxCap varchar(12), 
@GTStxNCap varchar(12),  
@BeginDate bDate,
@EndDate bDate		
		
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-----------------------------------------------------------------------
--AP Section
--execute brptGST_APactivity 'GSTpcap','GSTpnc', 1, '4/1/09','5/1/09'
--execute brptGST_ARactivity 'GSTs', '','', 1 , '4/1/09','5/1/09'
--
--
--Declare @GTSTaxCode varchar(12) 
--set @GTSTaxCode = 'GSTs'
--
--Declare @ExportSales varchar (12)
--set @ExportSales = 'GSTexport'
-- 
--Declare @GTStxFree varchar(12) 
--set @GTStxFree = ''
---------------------------------------------------------------
--Declare @ARCo  bCompany
--set @ARCo = '1'
--
--Declare @APCo  bCompany
--set @APCo = '1'
-----------------------------------------------------------------
--Declare @GTStxCap varchar(12) 
--set @GTStxCap = 'GSTpcap'
--
--Declare @GTStxNCap varchar(12) 
--set @GTStxNCap = 'GSTpnc'
-----------------------------------------------------------------
--
--Declare @BeginDate bDate 
--set @BeginDate = '1950-01-01'
--
--Declare @EndDate bDate
--set @EndDate = '2050-12-31'
------------------------------------------------------------------------





declare @APtable table
(Vendor varchar(65),
VendorName varchar(60),
Invoice bAPReference ,
InvoiceDate  datetime,
AccountingMth  datetime,
GLACCT  bGLAcct,
TaxCode  bTaxCode,
PurchaseType  varchar (25),
GSTSort  Int,
Amount  bDollar,
GSTTaxRate  bRate,
Tax  bDollar,
[Retention]  bDollar,
GSTonRetention  bDollar,
Total  bDollar)

----
----execute brptGST_APactivity 'GSTpcap','GSTpnc', 1, '4/1/09','5/1/09'
insert into @APtable execute brptGST_APactivity @GTStxCap, @GTStxNCap, @APCo, @BeginDate, @EndDate
--
--select * from @APtable
--
declare @G11 bDollar
select @G11 = sum(isnull(Amount, 0) ) from @APtable where PurchaseType = 'Non Capital Purchases'

declare @G10 bDollar
select @G10 = sum(isnull(Amount, 0) ) from @APtable where PurchaseType = 'Capital Purchases'


----------------------------------------------------------------------------------------------



declare @ARtable table
(Customer varchar (60),
Invoice varchar (10),
Amount bDollar,
[Retention] bDollar,
RetentionBilled bDollar,
BASbasis bDollar,
GSTCalculated bDollar,
SalesType varchar (25),
GSTSort int)

--execute dbo.brptGST_ARactivity @GTSTaxCode, @ExportSales, @GTStxFree, @ARCo, @BeginDate, @EndDate
--
--insert into @ARtable execute brptGST_ARactivity 'GSTs', '','', 1 , '2/1/09','7/1/09'
--
--
--select * from @ARtable


insert into @ARtable execute dbo.brptGST_ARactivity @GTSTaxCode, @ExportSales, @GTStxFree, @ARCo, @BeginDate, @EndDate
--
Declare @G1 bDollar
select @G1 = sum(isnull(BASbasis,0)) from @ARtable where SalesType = 'Total sales G1'

Declare @G2 bDollar
select @G2 = sum(isnull(BASbasis,0)) from @ARtable where SalesType = 'Export sales G2'

Declare @G3 bDollar
select @G3 = sum(isnull(BASbasis,0)) from @ARtable where SalesType = 'Other GST-free sales G3'
--

--select * from @ARtable
--
--select @G1


----------------------------------------------------------------------------------------------

select
@GTStxCap as 'GST_Cap_Acct',
@GTStxNCap as 'GST_NCap_Acct',
@GTSTaxCode  as 'GST_TotalSales', 
@ExportSales as 'GST_ExportSales', 
@GTStxFree as 'GSTfreeSales',
@ARCo as 'AR_Company', 
@APCo as 'AP_Company',
--'AR Company ' + @ARCo + ', AP Company ' + @APCo,
@BeginDate as 'BeginDate',
@EndDate as 'EndDate',
isnull(@G1, 0) as 'G1',
isnull(@G2, 0) as 'G2',
isnull(@G3,0) as 'G3',
isnull(@G10,0) as 'G10',
isnull(@G11,0) as 'G11'

END


GO
GRANT EXECUTE ON  [dbo].[brptGST_Main] TO [public]
GO
