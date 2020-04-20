SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[vspAPTaxableCreditorVal]
/****************************************************************************
* CREATED BY:	GF 02/13/2013 TFS-41052 AP Taxable Payment Reporting Enhancement
* MODIFIED BY:	GF 06/10/2013 TFS-52548 discount taken deduct from amount paid in year
*
*
* USAGE:
* Validates the Creditor from the AP Taxable Payment Reporting form / AP ATO Payee
* Taxable Payment form and returns vendor information from AP Vendor Master.
* Also retrieves tax year paid gst, total paid, and no abn tax totals.
*
*
* INPUT PARAMETERS:
* @APCo					AP Company
* @TaxYear				AP Reporting Tax Year
* @VendorGroup			AP Vendor Group
* @Creditor				AP Creditor to validate sort name or number
*
*
* OUTPUT PARAMETERS:
* @CreditorOut			Vendor Number
* @PayeeName			Vendor Name
* @Phone				Vendor Phone
* @Address				Vendor Address
* @City					Vendor City
* @State				Vendor State
* @ZipCode				Vendor Zip Code
* @Country				Vendor Country
* @AusBusNbr			Vendor Australia Business No.
* @V1099YN				Subject to Tax restriction
* @TotalPaid			Total Paid to vendor (includes GST)
* @TotalGST				Total GST Paid
* @NoABNTax				Non ABN Tax Amount
* @TotalATOPaid			Total ato paid
* @TotalATOGST			total gst paid
* @CreditorRecordsExist	flag to indicate payee records exist for creditor
* @AmendedRecordsExist	flag to indicate payee amended records exist for creditor
* @Address2				Vendor Address 2
*
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@APCo bCompany = NULL
 ,@TaxYear SMALLINT = NULL
 ,@VendorGroup bGroup = NULL
 ,@Creditor VARCHAR(15) = NULL
 ,@CreditorOut bVendor = NULL OUTPUT
 ,@PayeeName VARCHAR(60) = NULL OUTPUT
 ,@Phone VARCHAR(15) = NULL OUTPUT
 ,@Address VARCHAR(60) = NULL OUTPUT
 ,@City VARCHAR(60) = NULL OUTPUT
 ,@State VARCHAR(4) = NULL OUTPUT
 ,@ZipCode VARCHAR(12) = NULL OUTPUT
 ,@Country VARCHAR(2) = NULL OUTPUT
 ,@AUBusNbr VARCHAR(20) = NULL OUTPUT
 ,@V1099YN CHAR(1) = 'N' OUTPUT
 ,@TotalPaid bDollar = 0 OUTPUT
 ,@TotalGST bDollar = 0 OUTPUT
 ,@NoABNTax bDollar = 0 OUTPUT
 ,@TotalATOPaid bDollar = 0 OUTPUT
 ,@TotalATOGST bDollar = 0 OUTPUT
 ,@CreditorRecordsExist VARCHAR(1) = 'N' OUTPUT
 ,@AmendedRecordsExist VARCHAR(1) = 'N' OUTPUT
 ,@Address2 VARCHAR(60) = NULL OUTPUT
 ,@Msg VARCHAR(255) OUTPUT
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @BeginMth DATETIME, @EndMth DATETIME,
		@ValidYear DATETIME, @DefaultCountry VARCHAR(2), @V1099AddressSeq TINYINT

SET @rcode = 0
SET @TotalPaid = 0
SET @TotalGST = 0
SET @NoABNTax = 0
SET @CreditorRecordsExist = 'N'
SET @AmendedRecordsExist = 'N'

---- get vendor group from HQCo
SELECT @VendorGroup = ISNULL(@VendorGroup, h.VendorGroup)
		,@DefaultCountry = h.DefaultCountry
FROM dbo.APCO c WITH (NOLOCK)
JOIN dbo.HQCO h WITH (NOLOCK) ON h.HQCo = c.APCo
WHERE c.APCo = @APCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = 'Error retrieving Vendor Group for AP Company.'  
	SET @rcode = 1
	GOTO vspexit
	END
 

---- If @Creditor is numeric then try to find Creditor number
IF dbo.bfIsInteger(@Creditor) = 1 AND LEN(@Creditor) < 7
	BEGIN
	SELECT	@CreditorOut = v.Vendor, @Msg = v.Name,
			@Address = v.[Address],	@Address2 = v.[Address2], @City = v.City,	@State = v.[State], 
			@ZipCode = v.Zip, @Country = ISNULL(v.Country, ISNULL(@DefaultCountry,'')),
			@V1099YN = v.V1099YN, @AUBusNbr = v.AusBusNbr,
			@PayeeName = v.Name, @Phone = v.Phone,
			@V1099AddressSeq = v.V1099AddressSeq
	FROM dbo.APVM v (NOLOCK)
	WHERE v.VendorGroup = @VendorGroup
		AND v.Vendor = CONVERT(int, CONVERT(float, @Creditor))
	END

---- if not numeric or not found try to find as Sort Name
IF @CreditorOut IS NULL
	BEGIN
	SELECT	@CreditorOut = v.Vendor, @Msg = v.Name,
			@Address = v.[Address],	@Address2 = v.[Address2], @City = v.City,	@State = v.[State], 
			@ZipCode = v.Zip, @Country = ISNULL(v.Country, ISNULL(@DefaultCountry,'')),
			@V1099YN = v.V1099YN, @AUBusNbr = v.AusBusNbr,
			@PayeeName = v.Name, @Phone = v.Phone,
			@V1099AddressSeq = v.V1099AddressSeq
	FROM dbo.APVM v (NOLOCK)
	WHERE v.VendorGroup = @VendorGroup
		AND v.SortName = UPPER(@Creditor)
	ORDER BY v.SortName
    
	---- if not found,  try to find closest
	IF @@ROWCOUNT = 0 
		BEGIN	
		SET ROWCOUNT 1
		SELECT	@CreditorOut = v.Vendor, @Msg = v.Name,
				@Address = v.[Address],	@Address2 = v.[Address2], @City = v.City,	@State = v.[State], 
				@ZipCode = v.Zip, @Country = ISNULL(v.Country, ISNULL(@DefaultCountry,'')),
				@V1099YN = v.V1099YN, @AUBusNbr = v.AusBusNbr,
				@PayeeName = v.Name, @Phone = v.Phone,
				@V1099AddressSeq = v.V1099AddressSeq
		FROM dbo.APVM v (NOLOCK) 
		WHERE	v.VendorGroup = @VendorGroup
			AND v.SortName LIKE UPPER(@Creditor) + '%'
		ORDER BY v.SortName
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT @Msg = 'Not a valid Creditor.'
			RETURN 1
			END
		END
	END

---- if we have a V1099 Address Sequence use to get creditor address
IF @V1099AddressSeq IS NOT NULL
	BEGIN
	SELECT @Address = APAA.[Address], @Address2 = APAA.[Address2], @City = APAA.[City],
			@State = APAA.[State], @ZipCode = APAA.[Zip], 
			@Country = ISNULL(APAA.Country, ISNULL(@DefaultCountry,''))
	FROM dbo.bAPAA APAA
	WHERE APAA.VendorGroup = @VendorGroup
		AND APAA.Vendor = @CreditorOut
		AND APAA.AddressSeq = @V1099AddressSeq
	END

---- tax year must not be null
IF @TaxYear IS NULL
	BEGIN
	--SET @Msg = 'Missing Tax Year!'
	--SET @rcode = 1
	GOTO vspexit
	END
    
---- valid year?
SET @ValidYear = CONVERT(DATETIME, '01/01/' + CONVERT(CHAR(4), @TaxYear), 101)
IF ISDATE(@ValidYear) = 0
	BEGIN
 --	SET @Msg = 'Invalid Tax Year!'
	--SET @rcode = 1
	GOTO vspexit
	END  

---- check if records exist for creditor
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @APCo	AND TaxYear = @TaxYear
					AND VendorGroup = @VendorGroup AND Vendor = @CreditorOut)
	BEGIN
	SET @CreditorRecordsExist = 'Y'
	END

---- check if amended records exist for creditor
IF EXISTS(SELECT 1 FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @APCo	AND TaxYear = @TaxYear
					AND VendorGroup = @VendorGroup AND Vendor = @CreditorOut AND AmendedDate IS NOT NULL)
	BEGIN
	SET @AmendedRecordsExist = 'Y'
	END
    
---- create a begin month and end month for the tax year
SET @BeginMth = CONVERT(DATETIME, '07/01/' + CONVERT(CHAR(4),  @TaxYear - 1), 101)
SET @EndMth = CONVERT(DATETIME, '06/01/' + CONVERT(CHAR(4), @TaxYear), 101)

---- get creditor total paid and total GST paid
----TFS-52548
SELECT @TotalPaid = SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0))
	  ,@TotalGST  = SUM(ISNULL(APTD.TotTaxAmount, 0))
FROM dbo.bAPTD APTD WITH (NOLOCK)
INNER JOIN dbo.bAPTH APTH ON APTH.APCo=APTD.APCo AND APTH.Mth=APTD.Mth AND APTH.APTrans=APTD.APTrans
WHERE APTD.APCo = @APCo
	AND APTD.Status = 3
	AND APTD.PaidMth BETWEEN @BeginMth AND @EndMth
	AND APTH.Vendor = @CreditorOut
	AND APTH.InUseBatchId IS NULL
HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0

---- get creditor total paid and total GST paid for invoices where V1099YN = 'Y'
----TFS-52548
SELECT @TotalATOPaid = SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0))
	  ,@TotalATOGST  = SUM(ISNULL(APTD.TotTaxAmount, 0))
FROM dbo.bAPTD APTD WITH (NOLOCK)
INNER JOIN dbo.bAPTH APTH ON APTH.APCo=APTD.APCo AND APTH.Mth=APTD.Mth AND APTH.APTrans=APTD.APTrans
WHERE APTD.APCo = @APCo
	AND APTD.Status = 3
	AND APTD.PaidMth BETWEEN @BeginMth AND @EndMth
	AND APTH.Vendor = @CreditorOut
	AND APTH.V1099YN = 'Y'
	AND APTH.InUseBatchId IS NULL
HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0



vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspAPTaxableCreditorVal] TO [public]
GO
