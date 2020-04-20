SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE proc [dbo].[vspAPT5018VendorVal]
/****************************************************************************
* CREATED BY:	GF 06/01/2013 TFS-47328 CA T5018 payments reporting
* MODIFIED BY:	
*
*
* USAGE:
* Validates the Vendor from the AP T5018 Payments Reporting Vendor related grid
* and the AP Taxable Payments Reporting forms
* returns vendor information from AP Vendor Master.
* Also retrieves total paid to vendor for the reporting period.
*
*
* INPUT PARAMETERS:
* @APCo					AP Company
* @VendorGroup			AP Vendor Group
* @Vendor				AP Vendor to validate sort name or number
* @PeriodEndDate		AP T5018 Reporting Period End Date
* @UseThreshold			Flag to indicate if the 500 minimum threshold applies when getting the total reportable amount paid. Vendor Pay grid.
*
*
* OUTPUT PARAMETERS:
* @VendorOut			Vendor Number
* @VendorName			Vendor Name
* @Phone				Vendor Phone
* @Address				Vendor Address
* @Address2				Vendor Address 2
* @City					Vendor City
* @State				Vendor State
* @ZipCode				Vendor Zip Code
* @Country				Vendor Country
* @T5BusinessNbr		Vendor T5 Business No.
* @T5BusTypeCode		Vendor T5 Business type code
* @T5PartnerFIN			Vendor T5 FIN
* @T5SocInsNbr			Vendor T5 SIN
* @T5FirstName			Vendor T5 First Name
* @T5MiddleInit			Vendor T5 Middle Init
* @T5LastName			Vendor T5 Last Name
* @V1099YN				Subject to reporting currently using V1099YN flag
* @TotalPaid			Total Paid to vendor (includes tax)
* @TotalTax				Total Tax Paid (GST/PST/HST)
* @TotalReportablePaid		Total Reportable paid to vendor (includes tax) V1099YN = 'Y'
* @TotalReportableTaxPaid	Total Reportable tax paid to vendor - V1900YN = 'Y'
* @VendorRecordsExist		flag to indicate vendor records exist for T5018 period
* @AmendedRecordsExist		flag to indicate vendor amended records exist for T5018 period
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@APCo bCompany = NULL
 ,@VendorGroup bGroup = NULL
 ,@Vendor VARCHAR(15) = NULL
 ,@PeriodEndDate bDate = NULL
 ,@UseThreshold CHAR(1) = 'N'
 ,@VendorOut bVendor = NULL OUTPUT
 ,@VendorName VARCHAR(60) = NULL OUTPUT
 ,@Phone VARCHAR(15) = NULL OUTPUT
 ,@Address VARCHAR(30) = NULL OUTPUT
 ,@Address2 VARCHAR(30) = NULL OUTPUT
 ,@City VARCHAR(28) = NULL OUTPUT
 ,@State VARCHAR(2) = NULL OUTPUT
 ,@ZipCode VARCHAR(10) = NULL OUTPUT
 ,@Country VARCHAR(3) = NULL OUTPUT
 ,@T5BusinessNbr VARCHAR(15) = NULL OUTPUT
 ,@T5BusTypeCode CHAR(1) = 'C' OUTPUT
 ,@T5PartnerFIN VARCHAR(9) = NULL OUTPUT
 ,@T5SocInsNbr VARCHAR(9) = NULL OUTPUT
 ,@T5FirstName VARCHAR(12) = NULL OUTPUT
 ,@T5MiddleInit VARCHAR(1) = NULL OUTPUT
 ,@T5LastName VARCHAR(20) = NULL OUTPUT
 ,@V1099YN CHAR(1) = 'N' OUTPUT
 ,@TotalPaid bDollar = 0 OUTPUT
 ,@TotalTax bDollar = 0 OUTPUT
 ,@TotalReportablePaid bDollar = 0 OUTPUT
 ,@TotalReportableTaxPaid bDollar = 0 OUTPUT
 ,@VendorRecordsExist VARCHAR(1) = 'N' OUTPUT
 ,@AmendedRecordsExist VARCHAR(1) = 'N' OUTPUT
 ,@Msg VARCHAR(255) OUTPUT
 )
AS
SET NOCOUNT ON

DECLARE @rcode INT, @FirstMth DATETIME, @LastMth DATETIME,
		@V1099AddressSeq TINYINT, @HQCountry VARCHAR(2),
		@StartMonth SMALLDATETIME, @EndMonth SMALLDATETIME


SET @rcode = 0
SET @TotalPaid = 0
SET @TotalTax = 0
SET @TotalReportablePaid = 0
SET @TotalReportableTaxPaid = 0
SET @VendorRecordsExist = 'N'
SET @AmendedRecordsExist = 'N'


---- get vendor group from HQCo
SELECT @VendorGroup = ISNULL(@VendorGroup, h.VendorGroup)
		,@HQCountry = h.DefaultCountry
FROM dbo.APCO c WITH (NOLOCK)
JOIN dbo.HQCO h WITH (NOLOCK) ON h.HQCo = c.APCo
WHERE c.APCo = @APCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = 'Error retrieving Vendor Group for AP Company.'  
	SET @rcode = 1
	GOTO vspexit
	END

---- must have period end date
IF @PeriodEndDate IS NULL
	BEGIN
	SET @Msg = 'Missing period end date.'  
	SET @rcode = 1
	GOTO vspexit
	END

---- get month range for period end date
exec @rcode = dbo.vspAPT5018PaymentGetMonthRange @APCo, @PeriodEndDate, @StartMonth OUTPUT, @EndMonth OUTPUT, @Msg OUTPUT
IF @rcode <> 0
	BEGIN
	RETURN 1
	END


---- If @Vendor is numeric then try to find vendor number
IF dbo.bfIsInteger(@Vendor) = 1 AND LEN(@Vendor) < 7
	BEGIN
	SELECT	@VendorOut = v.Vendor, @Msg = v.Name,
			@Address = SUBSTRING(v.[Address],1,30),
			@Address2 = SUBSTRING(v.[Address2],1,30),
			@City = SUBSTRING(v.City,1,28),
			@State = SUBSTRING(v.[State],1,2), 
			@ZipCode = SUBSTRING(v.Zip,1,10),
			@Country = ISNULL(v.Country, ISNULL(@HQCountry,'')),
			@V1099YN = v.V1099YN, @VendorName = v.Name, @Phone = v.Phone, @V1099AddressSeq = v.V1099AddressSeq,
			@T5BusinessNbr = ISNULL(v.T5BusinessNbr, '000000000RT0000'),
			@T5BusTypeCode = v.T5BusTypeCode, @T5PartnerFIN = v.T5PartnerFIN,
			@T5SocInsNbr = ISNULL(v.T5SocInsNbr, '000000000'),
			@T5FirstName = v.T5FirstName, @T5MiddleInit = v.T5MiddleInit,
			@T5LastName = v.T5LastName
	FROM dbo.APVM v (NOLOCK)
	WHERE v.VendorGroup = @VendorGroup
		AND v.Vendor = CONVERT(int, CONVERT(float, @Vendor))
	END

---- if not numeric or not found try to find as Sort Name
IF @VendorOut IS NULL
	BEGIN
	SELECT	@VendorOut = v.Vendor, @Msg = v.Name,
			@Address = SUBSTRING(v.[Address],1,30),
			@Address2 = SUBSTRING(v.[Address2],1,30),
			@City = SUBSTRING(v.City,1,28),
			@State = SUBSTRING(v.[State],1,2),
			@ZipCode = SUBSTRING(v.Zip,1,10),
			@Country = ISNULL(v.Country, ISNULL(@HQCountry,'')),
			@V1099YN = v.V1099YN, @VendorName = v.Name, @Phone = v.Phone, @V1099AddressSeq = v.V1099AddressSeq,
			@T5BusinessNbr = ISNULL(v.T5BusinessNbr, '000000000RT0000'),
			@T5BusTypeCode = v.T5BusTypeCode, @T5PartnerFIN = v.T5PartnerFIN,
			@T5SocInsNbr = ISNULL(v.T5SocInsNbr, '000000000'),
			@T5FirstName = v.T5FirstName, @T5MiddleInit = v.T5MiddleInit,
			@T5LastName = v.T5LastName
	FROM dbo.APVM v (NOLOCK)
	WHERE v.VendorGroup = @VendorGroup
		AND v.SortName = UPPER(@Vendor)
	ORDER BY v.SortName
    
	---- if not found,  try to find closest
	IF @@ROWCOUNT = 0 
		BEGIN	
		SET ROWCOUNT 1
		SELECT	@VendorOut = v.Vendor, @Msg = v.Name,
				@Address = SUBSTRING(v.[Address],1,30),
				@Address2 = SUBSTRING(v.[Address2],1,30),
				@City = SUBSTRING(v.City,1,28),
				@State = SUBSTRING(v.[State],1,2),
				@ZipCode = SUBSTRING(v.Zip,1,10),
				@Country = ISNULL(v.Country, ISNULL(@HQCountry,'')),
				@V1099YN = v.V1099YN, @VendorName = v.Name, @Phone = v.Phone, @V1099AddressSeq = v.V1099AddressSeq,
				@T5BusinessNbr = ISNULL(v.T5BusinessNbr, '000000000RT0000'),
				@T5BusTypeCode = v.T5BusTypeCode, @T5PartnerFIN = v.T5PartnerFIN,
				@T5SocInsNbr = ISNULL(v.T5SocInsNbr, '000000000'),
				@T5FirstName = v.T5FirstName, @T5MiddleInit = v.T5MiddleInit,
				@T5LastName = v.T5LastName
		FROM dbo.APVM v (NOLOCK) 
		WHERE v.VendorGroup = @VendorGroup
			AND v.SortName LIKE UPPER(@Vendor) + '%'
		ORDER BY v.SortName
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT @Msg = 'Not a valid Vendor.'
			RETURN 1
			END
		END
	END

---- if we have a V1099 Address Sequence use to get vendor address
IF @V1099AddressSeq IS NOT NULL
	BEGIN
	SELECT  @Address = SUBSTRING(APAA.[Address],1,30),
			@Address2 = SUBSTRING(APAA.[Address2],1,30),
			@City = SUBSTRING(APAA.City,1,28),
			@State = SUBSTRING(APAA.[State],1,2),
			@ZipCode = SUBSTRING(APAA.Zip,1,10),
			@Country = ISNULL(APAA.Country, ISNULL(@HQCountry,''))
	FROM dbo.bAPAA APAA
	WHERE APAA.VendorGroup = @VendorGroup
		AND APAA.Vendor = @VendorOut
		AND APAA.AddressSeq = @V1099AddressSeq
	END


---- check if records exist for vendor
IF EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail WHERE APCo = @APCo AND PeriodEndDate = @PeriodEndDate
					AND VendorGroup = @VendorGroup AND Vendor = @VendorOut)
	BEGIN
	SET @VendorRecordsExist = 'Y'
	END

---- check if amended records exist for vendor
IF EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail WHERE APCo = @APCo AND  PeriodEndDate = @PeriodEndDate
					AND VendorGroup = @VendorGroup AND Vendor = @VendorOut AND ReportTypeCode = 'A')
	BEGIN
	SET @AmendedRecordsExist = 'Y'
	END



---- get vendor total paid and total tax paid
SELECT @TotalPaid = SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0))
		,@TotalTax = SUM(ISNULL(APTD.GSTtaxAmt, 0)) + SUM(ISNULL(APTD.PSTtaxAmt, 0))
FROM dbo.bAPTD APTD WITH (NOLOCK)
INNER JOIN dbo.bAPTH APTH ON APTH.APCo=APTD.APCo AND APTH.Mth=APTD.Mth AND APTH.APTrans=APTD.APTrans
WHERE APTD.APCo = @APCo
	AND APTD.Status = 3
	AND APTD.PaidMth BETWEEN @StartMonth AND @EndMonth
	AND APTH.Vendor = @VendorOut
	AND APTH.InUseBatchId IS NULL
HAVING SUM(ISNULL(APTD.Amount, 0)) <> 0

------ get vendor total paid for invoices where V1099YN = 'Y'
SELECT @TotalReportablePaid = SUM(ISNULL(APTD.Amount, 0)) - SUM(ISNULL(APTD.DiscTaken, 0))
		,@TotalReportableTaxPaid = SUM(ISNULL(APTD.GSTtaxAmt, 0)) + SUM(ISNULL(APTD.PSTtaxAmt, 0))
FROM dbo.bAPTD APTD WITH (NOLOCK)
INNER JOIN dbo.bAPTH APTH ON APTH.APCo=APTD.APCo AND APTH.Mth=APTD.Mth AND APTH.APTrans=APTD.APTrans
WHERE APTD.APCo = @APCo
	AND APTD.Status = 3
	AND APTD.PaidMth BETWEEN @StartMonth AND @EndMonth
	AND APTH.Vendor = @VendorOut
	AND APTH.V1099YN = 'Y'
	AND APTH.InUseBatchId IS NULL  
HAVING SUM(ISNULL(APTD.Amount, 0)) >= CASE WHEN @UseThreshold = 'N' THEN 0 ELSE 500 END



vspexit:
	return @rcode








GO
GRANT EXECUTE ON  [dbo].[vspAPT5018VendorVal] TO [public]
GO
