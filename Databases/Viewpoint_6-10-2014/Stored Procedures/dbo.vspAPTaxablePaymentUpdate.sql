SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[vspAPTaxablePaymentUpdate]
/****************************************************************************
* CREATED BY:	GF 03/14/2013 TFS-43705 AP ATO enhancement
* MODIFIED BY:	GF 06/06/2013 TFS-47323 'CA' T5018 payemnts
*				GF 06/11/2013 TFS-52548 add history if vendor/creditor does not exist yet part of discount taken deduct from amount paid
*
*
* USAGE:
* updates APTH V1099YN flag and the tax year payment history payee amounts for the creditor (vendor).
* Called from the AP Taxable Payments Reporting Update process form.
*
* The update process form allows the user to check or uncheck the V1099YN flag.
* If there is an existing payee record for the creditor, then the Total Paid and Total GST for 'AU'
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
* @HQCountry			HQ Country 'AU' OR 'CA'
* @PeriodEndDate		AP T5018 Reporting Period End Date..
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
----TFS-47323
,@HQCountry		VARCHAR(2) = NULL
,@PeriodEndDate	SMALLDATETIME = NULL
,@Msg			VARCHAR(255)OUTPUT
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @ValidDate DATETIME, @BeginMth bMonth, @EndMth bMonth,
		@StartMonth SMALLDATETIME, @EndMonth SMALLDATETIME

SET @rcode = 0

---- check Reportable flag
IF @Reportable IS NULL
	BEGIN
 	SET @Msg = 'Missing Invoice Reportable Flag!'
	SET @rcode = 1
	RETURN 1
	END

----TFS-47323
IF ISNULL(@HQCountry,'') NOT IN ('AU', 'CA')
	BEGIN
 	SET @Msg = 'Invalid Country, must be [AU] or [CA]!'
	RETURN 1
	END
    

---- validate 'AU' parameters
IF @HQCountry = 'AU'
	BEGIN
	---- tax year must not be null
	IF @TaxYear IS NULL
		BEGIN
		SET @Msg = 'Missing Tax Year!'
		RETURN 1
		END
    
	---- valid year?
	SET @ValidDate = CONVERT(DATETIME, '01/01/' + CONVERT(CHAR(4), @TaxYear), 101)
	IF ISDATE(@ValidDate) = 0
		BEGIN
 		SET @Msg = 'Invalid Tax Year!'
		RETURN 1
		END 

	---- make sure tax year is not closed
	IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear AND TaxYearClosed = 'Y')
		BEGIN
		SET @Msg = 'Tax Year has been closed. Updates not allowed!'
		RETURN 1
		END
	END ---- 'AU'

ELSE
	BEGIN
	---- TFS-47323 validate 'CA' parameters
	IF @PeriodEndDate IS NULL
		BEGIN
		SET @Msg = 'Missing Reporting Period End Date!'
		RETURN 1
		END
        
	---- is end month a valid date?
	SET @ValidDate = CONVERT(DATETIME, @PeriodEndDate, 101)
	IF ISDATE(@ValidDate) = 0
		BEGIN
 		SET @Msg = 'Invalid Reporting Period End Date!'
		RETURN 1
		END
	END ---- 'CA'


---- update APTH flag and payment history if needed
BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

	---- update APTH.V1099YN flag
	UPDATE dbo.bAPTH SET V1099YN = @Reportable
	WHERE KeyID = @APTH_KeyId
	IF @@ROWCOUNT = 0
		BEGIN
		RAISERROR ('Error occurred updating APTH Reporting Flag!', 11, 1);
		END

	---- 'AU' taxable payment payee record update
	IF @HQCountry = 'AU'
		BEGIN
        
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
			END ----'AU'
		ELSE
			BEGIN
  
			---- create a begin month and end month for the tax year
			SET @BeginMth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
			SET @EndMth   = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)  


			---- if tax year exists but no creditor then add to history  
			IF EXISTS(SELECT 1 FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @APCo AND TaxYear = @TaxYear)
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
				END ---- TAX YEAR EXISTS    
			END ---- ADD 'AU' VENDOR TO HISTORY
		END ---- AU

	---- TFS-47323 'CA' T5018 payment vendor record update
	IF @HQCountry = 'CA'
		BEGIN

		---- if we have an AP ATO Payee record for the tax year and creditor then update
		IF EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail WHERE APCo = @APCo
							AND PeriodEndDate = @PeriodEndDate
							AND VendorGroup = @VendorGroup
							AND Vendor = @Creditor)
			BEGIN
  			UPDATE dbo.vAPT5018PaymentDetail
					SET  TotalPaid = CASE WHEN @Reportable = 'Y'
										  THEN TotalPaid + @TotalPaid
										  ELSE TotalPaid - @TotalPaid
										  END
			WHERE APCo = @APCo
				AND PeriodEndDate = @PeriodEndDate
				AND VendorGroup = @VendorGroup
				AND Vendor = @Creditor
			END          
		ELSE
			BEGIN
  
			---- get month range for period end date
			exec @rcode = dbo.vspAPT5018PaymentGetMonthRange @APCo, @PeriodEndDate, @StartMonth OUTPUT, @EndMonth OUTPUT, @Msg OUTPUT
			IF @rcode <> 0
				BEGIN
				RAISERROR ('Error occurred calculating month range for reporting update!', 11, 1);              
				END       
				
			---- if tax year exists but no creditor then add to history  
			IF EXISTS(SELECT 1 FROM dbo.vAPT5018Payment WHERE APCo = @APCo AND PeriodEndDate = @PeriodEndDate)
				BEGIN
                
				---- insert a record for each vendor that has received payment in the period end date.
				---- the APTH.V1099YN flag is used to validate invoices that are reportable for the vendor.
				INSERT INTO dbo.vAPT5018PaymentDetail
						(
							APCo, PeriodEndDate, VendorGroup, Vendor, VendorName, [Address], Address2, City,
							[State], PostalCode, Country, T5BusTypeCode, T5BusinessNbr, T5PartnerFIN, T5FirstName,
							T5MiddleInit, T5LastName, T5SocInsNbr, ReportTypeCode, TotalPaid
						)

				SELECT  @APCo, @PeriodEndDate, @VendorGroup, @Creditor, APVM.Name,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address],1,30)  ELSE SUBSTRING(APVM.[Address],1,30)  END,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address2],1,30) ELSE SUBSTRING(APVM.[Address2],1,30) END,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[City],1,28)		ELSE SUBSTRING(APVM.[City],1,28)	 END,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[State],1,2)		ELSE SUBSTRING(APVM.[State],1,2)	 END,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Zip],1,10)		ELSE SUBSTRING(APVM.[Zip],1,10)		 END,
						CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Country] ELSE ISNULL(APVM.Country, HQCO.DefaultCountry) END,
						APVM.T5BusTypeCode,
						ISNULL(APVM.T5BusinessNbr, '000000000RZ0000'),	  
						APVM.T5PartnerFIN, 
						APVM.T5FirstName, 
						APVM.T5MiddleInit, 
						APVM.T5LastName,
						CASE WHEN APVM.T5SocInsNbr IS NOT NULL THEN APVM.T5SocInsNbr ELSE '000000000' END,
						'O', ISNULL(AmtPaidInYear, 0)
				FROM dbo.bAPVM APVM
				INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = @APCo
				LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = APVM.VendorGroup AND APAA.Vendor = APVM.Vendor AND APAA.AddressSeq = APVM.V1099AddressSeq
						CROSS APPLY  
						(
						SELECT  SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken,0)) AmtPaidInYear
							FROM dbo.bAPTD APTD WITH (NOLOCK)
							INNER JOIN dbo.bAPTH APTH ON APTH.APCo = APTD.APCo AND APTH.Mth = APTD.Mth AND APTH.APTrans = APTD.APTrans
							WHERE APTD.APCo = @APCo
							AND APTD.Status = 3
							AND APTD.PaidMth BETWEEN @StartMonth AND @EndMonth
							AND APTH.Mth = APTD.Mth 
							AND APTH.APTrans = APTD.APTrans
							AND APTH.V1099YN = 'Y'
							AND APTH.VendorGroup = APVM.VendorGroup
							AND APTH.Vendor = APVM.Vendor
							HAVING SUM(ISNULL(APTD.Amount, 0)) >= 500
							) APTD

				WHERE APVM.VendorGroup = @VendorGroup
					AND APVM.Vendor = @Creditor
					AND NOT EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail
									WHERE APCo = @APCo
										AND PeriodEndDate = @PeriodEndDate
										AND VendorGroup = APVM.VendorGroup
										AND Vendor = APVM.Vendor)  
				END ---- PERIOD END DATE EXISTS IN HISTORY
			END ---- ADD VENDOR TO HISTORY
		END ----CA



	---- insert for vendor/creditor payments has completed. commit transaction
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
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspAPTaxablePaymentUpdate] TO [public]
GO
