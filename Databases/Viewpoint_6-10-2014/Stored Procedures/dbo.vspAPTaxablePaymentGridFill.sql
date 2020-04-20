SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE proc [dbo].[vspAPTaxablePaymentGridFill]
/****************************************************************************
* CREATED BY:	GF 02/13/2013 TFS-41052 AP Taxable Payment Reporting Enhancement
* MODIFIED BY:	GF 06/06/2013 TFS-47322 Added 'CA' T5018 payments reporting
*				GF 06/10/2013 TFS-52548 discount taken deduct from amount paid
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
* @PeriodEndDate			AP T5018 payment reporting period end date
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
 ----TFS-47322
 ,@PeriodEndDate SMALLDATETIME = NULL
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @StartMonth DATETIME, @EndMonth DATETIME, @ValidDate DATETIME,
		@Style INT, @HQCountry VARCHAR(2), @Msg VARCHAR(255)

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
		 ----TFS-47322                                         
		,@HQCountry = HQCO.DefaultCountry                                         
FROM dbo.HQCO HQCO WHERE HQCO.HQCo = @APCo


---- validate inputs for 'AU'
IF @HQCountry = 'AU'
	BEGIN
	---- tax year must not be null
	IF @TaxYear IS NULL
		BEGIN
		SET @TaxYear = 1980
		--RETURN 1
		END
    ELSE
		BEGIN  
		---- valid year?
		SET @ValidDate = CONVERT(DATETIME, '01/01/' + CONVERT(CHAR(4), @TaxYear), 101)
		IF ISDATE(@ValidDate) = 0
			BEGIN
 			SET @TaxYear = 1980
			--RETURN 1
			END
		END      
	END
    
----TFS-47322 validate inputs for 'CA'
IF @HQCountry = 'CA'
	BEGIN
  
	---- must have a reporting period
	IF @PeriodEndDate IS NULL
		BEGIN
		SET @PeriodEndDate = '12/31/1980'
		--RETURN 1
		END
    ELSE
		BEGIN  
		---- valid start month?
		SET @ValidDate = CONVERT(DATETIME, @PeriodEndDate, 101)
		IF ISDATE(@ValidDate) = 0
			BEGIN
 			SET @PeriodEndDate = '12/31/1980'
			--RETURN 1
			END
		END
        
	---- get month range for period end date
	exec @rcode = dbo.vspAPT5018PaymentGetMonthRange @APCo, @PeriodEndDate, @StartMonth OUTPUT, @EndMonth OUTPUT, @Msg OUTPUT
	IF @rcode <> 0
		BEGIN
		--SET @StartMonth = '01/01/1980'
		--SET @EndMonth = '12/01/1980'
		RETURN 1
		END
	END
    

---- initialize tax payments
BEGIN TRY

	---- 'AU' ATO tax payments reporting grid fill
	IF @HQCountry = 'AU'
		BEGIN

		---- create a begin month and end month for the tax year
		SET @StartMonth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
		SET @EndMonth   = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)

		---- create result set to fill grid for with inovices that have been paid with the tax year
		SELECT   APTH.KeyID			AS [KeyID]
				,CASE APTH.V1099YN WHEN 'Y' THEN 'Y' ELSE 'N' END AS [Reportable]
				,CASE APTH.V1099YN WHEN 'Y' THEN 'Y' ELSE 'N' END AS [V1099YN]
				,CAST(CAST(DATEPART(mm, APTH.Mth) AS VARCHAR(2)) + '/' + CAST(DATEPART(yyyy, APTH.Mth) AS VARCHAR(4)) AS VARCHAR) AS [ExpMth]
				,APTH.APTrans		AS [APTrans]
				,APTH.APRef			AS [APRef]
				,APTH.[Description] AS [Description]
				,CONVERT(VARCHAR(20), APTH.InvDate, @Style) AS [InvDate]
				,APTH.InvTotal		AS [InvTotal]
				,ISNULL(InvRetention,0)	AS [InvRetention]
				,AmtPaidInYear		AS [AmtPaidInYear]
				,TotalTaxAmt		AS [TotalTaxAmt]
				,0					AS [TotalPST] ---- CA only
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
				 AND APTD.PaidMth BETWEEN @StartMonth AND @EndMonth
				 HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0
				 ) APTD
		WHERE APTH.APCo = @APCo
			AND APTH.Vendor = ISNULL(@Creditor, APTH.Vendor)
			AND (@ShowSubjectToTax = 'N'
				OR (@ShowSubjectToTax = 'Y' AND APTH.V1099YN = 'Y'))
			AND APTH.InUseBatchId IS NULL
		ORDER BY APTH.APCo, APTH.Mth, APTH.APTrans

		END ----END AU
	ELSE
		----TFS-47322 'CA' t5018 payments reporting grid fill 
		BEGIN

		---- create result set to fill grid for with inovices that have been paid within the starnt/end month range
		SELECT   APTH.KeyID			AS [KeyID]
				,CASE APTH.V1099YN WHEN 'Y' THEN 'Y' ELSE 'N' END AS [Reportable]
				,CASE APTH.V1099YN WHEN 'Y' THEN 'Y' ELSE 'N' END AS [V1099YN]
				,CAST(CAST(DATEPART(mm, APTH.Mth) AS VARCHAR(2)) + '/' + CAST(DATEPART(yyyy, APTH.Mth) AS VARCHAR(4)) AS VARCHAR) AS [ExpMth]
				,APTH.APTrans		AS [APTrans]
				,APTH.APRef			AS [APRef]
				,APTH.[Description] AS [Description]
				,CONVERT(VARCHAR(20), APTH.InvDate, @Style) AS [InvDate]
				,APTH.InvTotal		AS [InvTotal]
				,ISNULL(InvRetention,0)	AS [InvRetention]
				,AmtPaidInYear		AS [AmtPaidInYear]
				,TotalTaxAmt		AS [TotalTaxAmt]
				,TotalPST			AS [TotalPST]
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
				SELECT  SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0)) AmtPaidInYear
					   ,SUM(ISNULL(APTD.GSTtaxAmt, 0)) TotalTaxAmt ---- + SUM(ISNULL(APTD.PSTtaxAmt, 0)) TotalTaxAmt
					   ,SUM(ISNULL(APTD.PSTtaxAmt, 0)) TotalPST
				 FROM dbo.bAPTD APTD WITH (NOLOCK)
				 WHERE APTH.APCo = APTD.APCo 
				 AND APTH.Mth = APTD.Mth 
				 AND APTH.APTrans = APTD.APTrans
				 AND APTD.Status = 3
				 AND APTD.PaidMth BETWEEN @StartMonth AND @EndMonth
				 HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0
				 ) APTD
		WHERE APTH.APCo = @APCo
			AND APTH.Vendor = ISNULL(@Creditor, APTH.Vendor)
			AND (@ShowSubjectToTax = 'N'
				OR (@ShowSubjectToTax = 'Y' AND APTH.V1099YN = 'Y'))
			AND APTH.InUseBatchId IS NULL
		ORDER BY APTH.APCo, APTH.Mth, APTH.APTrans

		END ---- END 'CA'

        
END TRY
BEGIN CATCH
    -- Test XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should 
        --     be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and
        --     a commit or rollback operation would generate an error.
	IF XACT_STATE() <> 0
		BEGIN
		ROLLBACK TRANSACTION
		SET @Msg = CAST(ERROR_MESSAGE() AS VARCHAR(200)) 
		RETURN 1
		END
END CATCH

RETURN 0

	
--vspexit:
--	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspAPTaxablePaymentGridFill] TO [public]
GO
