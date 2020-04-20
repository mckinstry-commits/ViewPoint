SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE  procedure [dbo].[vspAPAUATOPayeeTaxPaymentsInit]
/******************************************************
* CREATED BY:	GF 02/26/2013 TFS-42329
* MODIFIED By:	GF 06/10/2013 TFS-52548 deduct discount taken from paid amount
*
*
* Usage: Calculates Paid Amounts from APTD/APTH for creditors (vendors).
*		 Inserts Creditor information and amounts into vAPAUPayeeTaxPaymentATO table.
*		 Called from APAUPayerTaxPaymentATO form.	
*
*
* Input params:
*
* @APCo			AP Company
* @Taxyear		Reporting Tax Year
* @Overwrite	Flag to indicate if replacing or adding to tax payments.
*			'Y' - all creditor tax payments will be overwritten.
*			'N' - only creditors not already in tax payment table will be added.
*
* Output params:
* @Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@APCo bCompany = NULL
 ,@TaxYear CHAR(4) = NULL
 ,@Overwrite CHAR(1) = 'Y'
 ,@Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @BeginMth bMonth, @EndMth bMonth, @ValidYear DATETIME,
		@VendorGroup bGroup


SET @rcode = 0
IF @Overwrite IS NULL SET @Overwrite = 'Y'


IF @APCo IS NULL
	BEGIN
	SET @Msg='Missing AP Company!'
	SET @rcode=1
	GOTO vspexit
	END

IF @TaxYear IS NULL
	BEGIN
	SET @Msg='Missing Tax Year!'
	SET @rcode=1
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

----validate tax year is not closed
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo  =@APCo AND TaxYear = @TaxYear AND TaxYearClosed = 'Y')
	BEGIN
	SET @Msg = 'Cannot initialize tax payments. The tax year is closed.'
	SET @rcode = 1
	GOTO vspexit
	END  

---- get vendor group from HQCo
SELECT @VendorGroup = h.VendorGroup
FROM dbo.APCO c WITH (NOLOCK)
JOIN dbo.HQCO h WITH (NOLOCK) ON h.HQCo = c.APCo
WHERE c.APCo = @APCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = 'Error retrieving Vendor Group for AP Company.'  
	SET @rcode = 1
	GOTO vspexit
	END

---- create a begin month and end month for the tax year
SET @BeginMth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
SET @EndMth   = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)


---- initialize tax payments
BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;
  
	---- when overwrite flag = 'Y' then first delete existing rows Creditor tax payments
	IF @Overwrite = 'Y'
		BEGIN
		DELETE FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear   
		END

	---- insert a record for each creditor (vendor) that has received payment in the tax year.
	---- the APTH.V1099YN flag is used to validate invoices that are reportable for the creditor.
	INSERT INTO dbo.vAPAUPayeeTaxPaymentATO
	        (
				APCo, TaxYear, VendorGroup, Vendor, PayeeName, AusBusNbr, [Address],
				[Address2], City, [State], PostalCode, [Country], Phone, TotalNoABNTax, TotalGST, TotalPaid,
				AmendedDate
	        )
	SELECT  @APCo, @TaxYear, @VendorGroup, APVM.Vendor, APVM.Name, APVM.AusBusNbr,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Address] ELSE APVM.[Address] END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Address2] ELSE APVM.[Address2] END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[City]	   ELSE APVM.[City]    END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[State]   ELSE APVM.[State]   END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Zip]     ELSE APVM.[Zip]     END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Country] ELSE ISNULL(APVM.Country, HQCO.DefaultCountry) END,
			APVM.Phone, 0, ISNULL(TotalTaxAmt, 0), ISNULL(AmtPaidInYear, 0), NULL
	FROM dbo.bAPVM APVM
	INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = @APCo
	LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = APVM.VendorGroup AND APAA.Vendor = APVM.Vendor AND APAA.AddressSeq = APVM.V1099AddressSeq
			CROSS APPLY  
			(
			----TFS-52548
			SELECT  SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken,0)) AmtPaidInYear
				   ,SUM(ISNULL(APTD.TotTaxAmount, 0)) TotalTaxAmt
			 FROM dbo.bAPTD APTD WITH (NOLOCK)
			 INNER JOIN dbo.bAPTH APTH ON APTH.APCo = APTD.APCo AND APTH.Mth = APTD.Mth AND APTH.APTrans = APTD.APTrans
			 WHERE APTD.APCo = @APCo
				AND APTD.Status = 3
				AND APTD.PaidMth BETWEEN @BeginMth AND @EndMth
				AND APTH.Mth = APTD.Mth 
				AND APTH.APTrans = APTD.APTrans
				AND APTH.V1099YN = 'Y'
				AND APTH.VendorGroup = APVM.VendorGroup
				AND APTH.Vendor = APVM.Vendor
			 HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0
			 ) APTD

	WHERE APVM.VendorGroup = @VendorGroup
		AND NOT EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO
						WHERE APCo = @APCo
							AND TaxYear = @TaxYear
							AND VendorGroup = APVM.VendorGroup
							AND Vendor = APVM.Vendor)


	---- insert for Creditor payments has completed. commit transaction
	COMMIT TRANSACTION;


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
		SET @rcode = 1
		END
END CATCH




			
vspexit:
	RETURN @rcode





GO
GRANT EXECUTE ON  [dbo].[vspAPAUATOPayeeTaxPaymentsInit] TO [public]
GO
