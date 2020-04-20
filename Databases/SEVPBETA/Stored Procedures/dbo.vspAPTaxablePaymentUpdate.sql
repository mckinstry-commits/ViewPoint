SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[vspAPTaxablePaymentUpdate]
/****************************************************************************
* CREATED BY:	GF 03/14/2013 TFS-43705 AP ATO enhancement
* MODIFIED BY:	GF 06/11/2013 TFS-52548 add history if vendor/creditor does not exist yet part of discount taken deduct from amount paid
*
*
*
* USAGE:
* updates APTH V1099YN flag and the tax year payment history payee amounts for the creditor (vendor).
* Called from the AP Taxable Payments Reporting Update process form.
*
* The update process form allows the user to check or uncheck the V1099YN flag.
* If there is an existing payee record for the creditor, then the Total Paid and Total GST
* will be updated with the invoice amounts.
* When flag is 'Y', then adding too
* When flag is 'N', then deducting from.
*
*
* INPUT PARAMETERS:
* @APCo					AP Company
* @TaxYear				Tax Year to update payee record for creditor when exists
* @VendorGroup			AP Vendor Group
* @Creditor				AP Creditor to update taxable payment
* @APTH_KeyId			APTH Record id to be updated. Also identifies vendor to update in history
* @Reportable			Value of V1099YN flag to update, can be either 'Y' or 'N'
* @TotalPaid			Amount paid in year
* @TotalGST				GST paid in year
*
*
* OUTPUT PARAMETERS:
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@APCo			bCompany = NULL
,@TaxYear		SMALLINT = NULL
,@VendorGroup	bGroup	 = NULL
,@Creditor		bVendor	 = NULL
,@APTH_KeyId	BIGINt  = NULL
,@Reportable	CHAR(1) = 'Y'
,@TotalPaid		bDollar = 0
,@TotalGST		bDollar = 0
,@Msg			VARCHAR(255) OUTPUT
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @ValidYear DATETIME, @BeginMth bMonth, @EndMth bMonth

SET @rcode = 0

---- tax year must not be null
IF @TaxYear IS NULL
	BEGIN
	SET @Msg = 'Missing Tax Year!'
	SET @rcode = 1
	GOTO vspexit
	END
    
---- valid year?
SET @ValidYear = CONVERT(DATETIME, '01/01/' + CONVERT(CHAR(4), @TaxYear), 101)
IF ISDATE(@ValidYear) = 0
	BEGIN
 	SET @Msg = 'Invalid Tax Year!'
	SET @rcode = 1
	GOTO vspexit
	END  

---- check Reportable flag
IF @Reportable IS NULL
	BEGIN
 	SET @Msg = 'Missing Invoice Reportable Flag!'
	SET @rcode = 1
	GOTO vspexit
	END 

---- make sure tax year is not closed
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear AND TaxYearClosed = 'Y')
	BEGIN
    SET @Msg = 'Tax Year has been closed. Updates not allowed!'
	SET @rcode = 1
	GOTO vspexit
	END
    
---- update APTH.V1099YN flag
UPDATE dbo.bAPTH SET V1099YN = @Reportable
WHERE KeyID = @APTH_KeyId
IF @@ROWCOUNT = 0
	BEGIN
    SET @Msg = 'Error occurred updating APTH Reporting Flag!'
	SET @rcode = 1
	GOTO vspexit
	END


---- if we have an AP ATO Payee record for the tax year and creditor then update
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @APCo
					AND TaxYear = @TaxYear
					AND VendorGroup = @VendorGroup
					AND Vendor = @Creditor)
	BEGIN
	UPDATE dbo.vAPAUPayeeTaxPaymentATO
			SET  TotalPaid = CASE WHEN @Reportable = 'Y'
								  THEN TotalPaid + @TotalPaid
								  ELSE TotalPaid - @TotalPaid
								  END
				,TotalGST = CASE WHEN @Reportable = 'Y'
								  THEN TotalGST + @TotalGST
								  ELSE TotalGST - @TotalGST
								  END
	WHERE APCo = @APCo
		AND TaxYear = @TaxYear
		AND VendorGroup = @VendorGroup
		AND Vendor = @Creditor
	END
ELSE
	BEGIN
  
	---- create a begin month and end month for the tax year
	SET @BeginMth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
	SET @EndMth   = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)  


	---- if tax year exists but no creditor then add to history  
	IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear)
		BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @APCo
							AND TaxYear = @TaxYear
							AND VendorGroup = @VendorGroup
							AND Vendor = @Creditor)
			BEGIN
			---- insert a record for each creditor (vendor) that has received payment in the tax year.
			---- the APTH.V1099YN flag is used to validate invoices that are reportable for the creditor.
			INSERT INTO dbo.vAPAUPayeeTaxPaymentATO
					(
						APCo, TaxYear, VendorGroup, Vendor, PayeeName, AusBusNbr, [Address],
						[Address2], City, [State], PostalCode, [Country], Phone, TotalNoABNTax, TotalGST, TotalPaid,
						AmendedDate
					)
			SELECT  @APCo, @TaxYear, @VendorGroup, @Creditor, APVM.Name, APVM.AusBusNbr,
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
						AND APTH.VendorGroup = @VendorGroup
						AND APTH.Vendor = @Creditor
					 HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0
					 ) APTD

			WHERE APVM.VendorGroup = @VendorGroup
				AND APVM.Vendor = @Creditor
				AND NOT EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO
								WHERE APCo = @APCo
									AND TaxYear = @TaxYear
									AND VendorGroup = @VendorGroup
									AND Vendor = @Creditor)
			END
		END          
	END  



	
vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspAPTaxablePaymentUpdate] TO [public]
GO
