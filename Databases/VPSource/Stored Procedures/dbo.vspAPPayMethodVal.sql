SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspAPPayMethodVal]

/***************************************************
* CREATED BY    : EN 01/09/2012
* Modified by	: KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
* Usage:
*   Validates AP Payment Method and returns various possible warnings for: 
*		AP Transaction Entry
*		AP Unapproved Invoice Entry
*		AP Recurring Invoices
*		AP Payment Workfile (KK - TK-11581)
*	
*
* Input:
*	@apco         AP Company
*	@vendorgrp	  Vendor Group
*	@vendor		  Vendor Code
*	@paymethod    AP Payment Method
*
* Output:
*   @msg          error message
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@apco bCompany = null,
 @vendorgrp bGroup = null, 
 @vendor bVendor = null,
 @paymethod char(1) = null,
 @msg varchar(80) OUTPUT)
 
AS
SET NOCOUNT ON

--validate input params
IF @apco IS NULL
BEGIN
	SELECT @msg = 'Missing AP Company'
	RETURN 1
END

IF @vendorgrp IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Group'
	RETURN 1
END

IF @vendor IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Code'
	RETURN 1
END

IF @paymethod IS NULL
BEGIN
	SELECT @msg = 'Missing Payment Method'
	RETURN 1
END

--Check routing information for EFT transactions
IF @paymethod = 'E'
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
	WHERE VendorGroup = @vendorgrp AND 
		  Vendor = @vendor

	--warn if Routing Info is not all setup for vendor
	IF (@DefaultCountry IN ('US', 'CA')	AND (@RoutingId IS NULL OR @BankAcct IS NULL)) OR
	   (@DefaultCountry IN ('AU')		AND (@AUVendorBSB IS NULL OR @AUVendorAccountNumber IS NULL))
	BEGIN
		SELECT @msg = 'EFT Routing information for this Vendor is incomplete '
		RETURN 1
	END
END

--check setup information for Credit Service transactions
IF @paymethod = 'S'
BEGIN
	DECLARE @CreditService tinyint,
			@CSCMAcct bCMAcct,
			@CDAcctCode varchar(5), 
			@CDCustID varchar(10), 
			@CDCodeWord varchar(20),
			@TCCo numeric(6,0),
			@TCAcct numeric(10,0)

	SELECT	@CreditService = APCreditService,
			@CSCMAcct = CSCMAcct,
			@CDAcctCode = CDAcctCode, 
			@CDCustID = CDCustID, 
			@CDCodeWord = CDCodeWord,
			@TCCo = TCCo,
			@TCAcct = TCAcct
	FROM dbo.bAPCO
	WHERE APCo = @apco

	--warn if no Credit Service is selected in AP Company
	IF @CreditService = 0
	BEGIN
		SELECT @msg = 'No Credit Service has been selected for this AP company '
		RETURN 1
	END

	--warn if Credit Service is selected in AP Company but Credit Service CM Acct is missing
	IF @CreditService <> 0 AND @CSCMAcct IS NULL
	BEGIN
		SELECT @msg = 'Credit Service CM Acct must be selected for this AP company '
		RETURN 1
	END

	-- warn if AP Company is set up to use credit service Comdata but missing some of the Comdata setup, or
	IF @CreditService = 1 AND (@CDAcctCode IS NULL OR @CDCustID IS NULL OR @CDCodeWord IS NULL)
	BEGIN
		SELECT @msg = 'Comdata setup for this AP company is incomplete '
		RETURN 1
	END
	 
	-- warn if AP Company is set up to use credit service T-Chek but missing some of the T-Chek setup
	IF @CreditService = 2 AND (@TCCo IS NULL OR @TCAcct IS NULL)
	BEGIN
		SELECT @msg = 'T-Chek setup for this AP company is incomplete '
		RETURN 1
	END

END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPPayMethodVal] TO [public]
GO
