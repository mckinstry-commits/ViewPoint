SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[vspAPTaxablePaymentGridFill]
/****************************************************************************
* CREATED BY:	GF 02/13/2013 TFS-41052 AP Taxable Payment Reporting Enhancement
* MODIFIED BY:	GF 06/10/2013 TFS-52548 discount taken deduct from amount paid
*
*
* USAGE:
* Fills grid with available AP Invoices that can be updated with the AP Invoice
* header reportable flag. APTH.V1099YN ?
*
*
* INPUT PARAMETERS:
* @APCo					AP Company
* @TaxYear				AP Reporting Tax Year
* @Creditor				AP Vendor restriction
* @ShowSubjectToTax		Subject to Tax restriction
*						'Y' - V1099YN = 'Y'
*						'N' - V1099YN = 'Y' OR 'N'
*
*
* OUTPUT PARAMETERS:
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@APCo bCompany = NULL,
 @TaxYear SMALLINT = NULL, 
 @Creditor bVendor = NULL,
 @ShowSubjectToTax CHAR(1) = 'N'
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @BeginMth DATETIME, @EndMth DATETIME, @ValidYear DATETIME,
		@Style INT

SET @rcode = 0
SET @Style = 101

----assume all if missing show subject to tax option
IF @ShowSubjectToTax IS NULL SET @ShowSubjectToTax = 'N'


---- get date display style from HQ Company
SELECT @Style = CASE HQCO.ReportDateFormat WHEN 1 THEN 101
										   WHEN 2 THEN 103
										   WHEN 3 THEN 111
										   ELSE 101
										   END
FROM dbo.HQCO HQCO WHERE HQCO.HQCo = @APCo


---- tax year must not be null
IF @TaxYear IS NULL
	BEGIN
	--SELECT @msg = 'Missing Tax Year!'
	SET @rcode = 1
	GOTO vspexit
	END
    
---- valid year?
SET @ValidYear = CONVERT(DATETIME, '01/01/' + CONVERT(CHAR(4), @TaxYear), 101)
IF ISDATE(@ValidYear) = 0
	BEGIN
 	--SELECT @msg = 'Invalid Tax Year!'
	SET @rcode = 1
	GOTO vspexit
	END  

---- create a begin month and end month for the tax year
SET @BeginMth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
SET @EndMth   = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)

---- create result set to fill grid for with inovices that have been paid with the tax year
SELECT   APTH.KeyID			AS [KeyID]
		,APTH.V1099YN		AS [Reportable]
		,APTH.V1099YN		AS [V1099YN]
		,CAST(CAST(DATEPART(mm, APTH.Mth) AS VARCHAR(2)) + '/' + CAST(DATEPART(yyyy, APTH.Mth) AS VARCHAR(4)) AS VARCHAR) AS [ExpMth]
		,APTH.APTrans		AS [APTrans]
		,APTH.APRef			AS [APRef]
		,APTH.[Description] AS [Description]
		,CONVERT(VARCHAR(20), APTH.InvDate, @Style) AS [InvDate]
		,APTH.InvTotal		AS [InvTotal]
		,ISNULL(InvRetention,0)	AS [InvRetention]
		,AmtPaidInYear		AS [AmtPaidInYear]
		,TotalTaxAmt		AS [TotalTaxAmt]
from dbo.APTH APTH WITH (NOLOCK)
	OUTER APPLY
		(
		 SELECT  SUM(ISNULL(APTL.Retainage, 0)) InvRetention
		 FROM dbo.bAPTL APTL WITH (NOLOCK)
		 WHERE APTH.APCo = APTL.APCo 
		 AND APTH.Mth = APTL.Mth 
		 AND APTH.APTrans = APTL.APTrans
		 ) APTL
	CROSS APPLY  
	    (
		 ----TFS-52548
		 SELECT  SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0)) AmtPaidInYear
			   ,SUM(ISNULL(APTD.TotTaxAmount, 0)) TotalTaxAmt
		 FROM dbo.bAPTD APTD WITH (NOLOCK)
		 WHERE APTH.APCo = APTD.APCo 
		 AND APTH.Mth = APTD.Mth 
		 AND APTH.APTrans = APTD.APTrans
		 AND APTD.Status = 3
		 AND APTD.PaidMth BETWEEN @BeginMth AND @EndMth
		 HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0
		 ) APTD
WHERE APTH.APCo = @APCo
	AND APTH.Vendor = ISNULL(@Creditor, APTH.Vendor)
	AND (@ShowSubjectToTax = 'N'
		OR (@ShowSubjectToTax = 'Y' AND APTH.V1099YN = 'Y'))
	AND APTH.InUseBatchId IS NULL
ORDER BY APTH.APCo, APTH.Mth, APTH.APTrans



	
vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspAPTaxablePaymentGridFill] TO [public]
GO
