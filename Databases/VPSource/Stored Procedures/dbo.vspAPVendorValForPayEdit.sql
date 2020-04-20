SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPVendorValForPayEdit    Script Date: 8/28/99 9:32:34 AM ******/
CREATE    proc [dbo].[vspAPVendorValForPayEdit]
/*************************************
* Created by:  EN 3/13/2012 - was using bspAPVendorValWithAddressDflts prior to this but needed Comdata email address validation
* Modified by: KK 05/01/12 - TK-14337 Changed ComData => Comdata 
*
* Usage:
* 	validates AP Vendors against APVM and checks for existence of Comdata email address
*   also validates vendor routing info for pay method 'E' (EFT) pay sequences
*   returns name, address, city, state and zip for form defaults
*
* Input params:
*	@vendgroup	AP Vendor Group
*	@vendor		AP Vendor
*
* Output params:
*	@vendrout	Vendor number
*	@name		Vendor name
*   @addnlinfo  Vendor's additional info
*	@address	Vendor's payment address
*	@city		Vendor's city
*	@state		Vendor's state
*	@zip		Vendor's zip
*	@msg		Error message
*
* Return code:
*	0=success, 1=failure
**************************************/
(@apco bCompany, 
 @vendgroup bGroup = NULL, 
 @vendor varchar(15) = NULL, 
 @paymethod char(1) = NULL,
 @vendrout bVendor = NULL OUTPUT,
 @name varchar(60) = NULL OUTPUT, 
 @addnlinfo varchar(60) = NULL OUTPUT, 
 @address varchar(60) = NULL OUTPUT,
 @city varchar(30) = NULL OUTPUT, 
 @state varchar(4) = NULL OUTPUT,
 @zip bZip = NULL OUTPUT, 
 @country char(2) OUTPUT,
 @cmacct bCMAcct OUTPUT, 
 @msg varchar(60) OUTPUT)

AS
SET NOCOUNT ON

if @vendrout = 0 -- #27144
BEGIN
	SELECT @vendrout = null
END

--validate input params
IF @vendgroup IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Group'
	RETURN 1
END
IF @vendor IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor'
	RETURN 1
END
IF @paymethod IS NULL
BEGIN
	SELECT @msg = 'Missing Pay Method'
	RETURN 1
END

/* If @vendor is numeric then try to find Vendor number */
IF dbo.bfIsInteger(@vendor) = 1 AND LEN(@vendor) < 7
BEGIN
	-- if isnumeric(@vendor) = 1 
	SELECT	@vendrout = v.Vendor,	@name = v.Name,	@addnlinfo = v.AddnlInfo, 
			@address = v.[Address],	@city = v.City,	@state = v.[State], 
			@zip = v.Zip, @cmacct = CMAcct,
			@country = ISNULL(v.Country, ISNULL(h.DefaultCountry,'')) 
	FROM dbo.APVM v (NOLOCK)
	LEFT JOIN dbo.HQCO h ON v.VendorGroup = h.VendorGroup
	WHERE	v.VendorGroup = @vendgroup AND 
			v.Vendor = CONVERT(int,CONVERT(float, @vendor))
END

/* if not numeric or not found try to find as Sort Name */
IF @vendrout IS NULL
-- if @@rowcount = 0
BEGIN
	SELECT	@vendrout = v.Vendor,	@name = v.Name,	@addnlinfo = v.AddnlInfo, 
			@address = v.[Address],	@city = v.City,	@state = v.[State], 
			@zip = v.Zip, @cmacct = CMAcct, 
			@country = ISNULL(v.Country, ISNULL(h.DefaultCountry,'')) 
	FROM dbo.APVM v (NOLOCK)
	LEFT JOIN dbo.HQCO h ON v.VendorGroup = h.VendorGroup
	WHERE	v.VendorGroup = @vendgroup AND 
			v.SortName = UPPER(@vendor) ORDER BY v.SortName

	/* if not found,  try to find closest */
	IF @@ROWCOUNT = 0
	BEGIN
		SET ROWCOUNT 1
		SELECT	@vendrout = v.Vendor,	@name = v.Name,	@addnlinfo = v.AddnlInfo, 
				@address = v.[Address],	@city = v.City,	@state = v.[State], 
				@zip = v.Zip, @cmacct = CMAcct, 
				@country = ISNULL(v.Country, ISNULL(h.DefaultCountry,'')) 
		FROM dbo.APVM v (NOLOCK) 
		LEFT JOIN dbo.HQCO h ON v.VendorGroup = h.VendorGroup
		WHERE	v.VendorGroup = @vendgroup AND 
				v.SortName LIKE UPPER(@vendor) + '%' ORDER BY v.SortName

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Not a valid Vendor'
			RETURN 1
		END
	END
END

IF @paymethod = 'S' --Pay Method is Credit Service
BEGIN
	DECLARE @APCreditService tinyint,
			@CreditServiceEmail varchar(60)
	
	SELECT @APCreditService = APCreditService FROM dbo.APCO WHERE APCo = @apco
	
	SELECT @CreditServiceEmail = CSEmail FROM dbo.APVM WHERE VendorGroup = @vendgroup AND Vendor = @vendor
		
	--CMAcct on the tran does not match APCO CSCMAcct
	IF @APCreditService = 1 AND (@CreditServiceEmail IS NULL OR @CreditServiceEmail = '')
	BEGIN
		SELECT @msg = 'Vendor requires a credit service email to make a payment '
		RETURN 1
	END
END
ELSE IF @paymethod = 'E' --Pay Method is EFT, check routing information in Vendor Master
BEGIN
	DECLARE @DefaultCountry char(2),
			@RoutingId varchar(34),
			@BankAcct varchar(35), 
			@AUVendorBSB varchar(6), 
			@AUVendorAccountNumber varchar(9)

	SELECT	@DefaultCountry = DefaultCountry
	FROM dbo.bHQCO
	WHERE HQCo = @apco

	SELECT	@RoutingId = RoutingId,
			@BankAcct = BankAcct, 
			@AUVendorBSB = AUVendorBSB, 
			@AUVendorAccountNumber = AUVendorAccountNumber
	FROM dbo.bAPVM WITH (NOLOCK)
	WHERE VendorGroup = @vendgroup AND 
		  Vendor = @vendor

	--warn if Routing Info is not all setup for vendor
	IF (@DefaultCountry IN ('US', 'CA')	AND (@RoutingId IS NULL OR @BankAcct IS NULL)) OR
	   (@DefaultCountry IN ('AU')		AND (@AUVendorBSB IS NULL OR @AUVendorAccountNumber IS NULL))
	BEGIN
		SELECT @msg = 'EFT Routing information for this Vendor is incomplete '
		RETURN 1
	END
END

SELECT @msg = @name
RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspAPVendorValForPayEdit] TO [public]
GO
