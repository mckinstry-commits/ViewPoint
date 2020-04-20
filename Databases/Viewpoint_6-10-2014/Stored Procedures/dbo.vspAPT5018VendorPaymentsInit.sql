SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE  procedure [dbo].[vspAPT5018VendorPaymentsInit]
/******************************************************
* CREATED BY:	GF 06/06/2013 TFS-47329 T5018 Payment
* MODIFIED By:
*
* Usage: Calculates Paid Amounts from APTD/APTH for vendors.
*		 Inserts vendor information and amounts into vAPT5018PaymentDetail table.
*		 Called from AP T5018 Payments form task drop down option.	
*
*
* Input params:
*
* @APCo				AP Company
* @PeriodEndDate	T5018 Reporting Period End Date
* @Overwrite		Flag to indicate if replacing or adding to payments.
*				'Y' - all vendor payments will be overwritten.
*				'N' - only vendros not already in payment detail table will be added.
*
* Output params:
* @Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@APCo bCompany = NULL
 ,@PeriodEndDate SMALLDATETIME = NULL
 ,@Overwrite CHAR(1) = 'Y'
 ,@Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @StartMonth SMALLDATETIME, @EndMonth SMALLDATETIME, @ValidDate DATETIME,
		@VendorGroup bGroup, @ErrMsg varchar(255)


SET @rcode = 0
IF @Overwrite IS NULL SET @Overwrite = 'Y'


IF @APCo IS NULL
	BEGIN
	SET @Msg='Missing AP Company!'
	RETURN 1
	END

IF @PeriodEndDate IS NULL
	BEGIN
	SET @Msg='Missing Reporting Period End Date!'
	RETURN 1
	END

---- valid period end date?
SET @ValidDate = CONVERT(DATETIME, @PeriodEndDate, 101)
IF ISDATE(@ValidDate) = 0
	BEGIN
 	--SELECT @msg = 'Invalid Period End Date!'
	RETURN 1
	END  

----validate reporting period is not closed
IF EXISTS(SELECT 1 FROM dbo.vAPT5018Payment WHERE APCo = @APCo AND PeriodEndDate = @PeriodEndDate AND PeriodClosed = 'Y')
	BEGIN
	SET @Msg = 'Cannot initialize vendor payments. The reporting period is closed.'
	RETURN 1
	END  

---- get vendor group from HQCo
SELECT @VendorGroup = h.VendorGroup
FROM dbo.APCO c WITH (NOLOCK)
JOIN dbo.HQCO h WITH (NOLOCK) ON h.HQCo = c.APCo
WHERE c.APCo = @APCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = 'Error retrieving Vendor Group for AP Company.'  
	RETURN 1
	END  


---- get month range for period end date
exec @rcode = dbo.vspAPT5018PaymentGetMonthRange @APCo, @PeriodEndDate, @StartMonth OUTPUT, @EndMonth OUTPUT, @Msg OUTPUT
IF @rcode <> 0
	BEGIN
	RETURN 1
	END
    

------ initialize vendor payments
BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;
  
	---- when overwrite flag = 'Y' then first delete existing rows vendor payments
	IF @Overwrite = 'Y'
		BEGIN
		DELETE FROM dbo.vAPT5018PaymentDetail WHERE APCo = @APCo AND PeriodEndDate = @PeriodEndDate   
		END

	---- insert a record for each vendor that has received payment in the period end date.
	---- the APTH.V1099YN flag is used to validate invoices that are reportable for the vendor.
	INSERT INTO dbo.vAPT5018PaymentDetail
	        (
			 APCo, PeriodEndDate, VendorGroup, Vendor, VendorName, [Address], Address2, City,
			 [State], PostalCode, Country, T5BusTypeCode, T5BusinessNbr, T5PartnerFIN, T5FirstName,
			 T5MiddleInit, T5LastName, T5SocInsNbr, ReportTypeCode, TotalPaid
	        )

	SELECT  @APCo, @PeriodEndDate, @VendorGroup, APVM.Vendor, APVM.Name,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address],1,30)  ELSE SUBSTRING(APVM.[Address],1,30)  END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address2],1,30) ELSE SUBSTRING(APVM.[Address2],1,30) END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[City],1,28)		ELSE SUBSTRING(APVM.[City],1,28)	 END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[State],1,2)		ELSE SUBSTRING(APVM.[State],1,2)	 END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Zip],1,10)		ELSE SUBSTRING(APVM.[Zip],1,10)		 END,
			CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Country] ELSE ISNULL(APVM.Country, HQCO.DefaultCountry) END,
			APVM.T5BusTypeCode,
			CASE WHEN APVM.T5BusinessNbr IS NOT NULL THEN APVM.T5BusinessNbr ELSE '000000000RZ0000' END,
			APVM.T5PartnerFIN, APVM.T5FirstName, APVM.T5MiddleInit, APVM.T5LastName,
			CASE WHEN APVM.T5SocInsNbr IS NOT NULL THEN APVM.T5SocInsNbr ELSE '000000000' END,
			'O', ISNULL(AmtPaidInYear, 0)
	FROM dbo.bAPVM APVM
	INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = @APCo
	LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = APVM.VendorGroup AND APAA.Vendor = APVM.Vendor AND APAA.AddressSeq = APVM.V1099AddressSeq
			CROSS APPLY  
			(
			----@TotalPaid = SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0))
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
		AND NOT EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail
						WHERE APCo = @APCo
							AND PeriodEndDate = @PeriodEndDate
							AND VendorGroup = APVM.VendorGroup
							AND Vendor = APVM.Vendor)


	---- insert for vendor payments has completed. commit transaction
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
		RETURN 1
		END
END CATCH



RETURN 0







GO
GRANT EXECUTE ON  [dbo].[vspAPT5018VendorPaymentsInit] TO [public]
GO
