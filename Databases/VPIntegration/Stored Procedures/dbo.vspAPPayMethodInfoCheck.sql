SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspAPPayMethodInfoCheck]

/***************************************************
* CREATED BY    : KK 03/02/12
* Modified by	: KK 03/15/12 - TK-12462 Modified the changes to contatenate the error message
*				  KK 03/19/12 - TK-12462 Removed check to Vendor Master Paymethod for CSEmail
*				  EN 4/4/2012 TK-12973 Fixed message for missing CSCMAcct and removed CMCo/CMAcct input params which are not needed
*				  KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
*
* Usage: Checks that all necessary information needed for valid AP Payment Method has been 
*		 entered in AP Company and AP Vendor and returns various possible warnings.
*		
*			
* DDFI Validation Procedure for:	
*		PayMethod(Seq 55) ValLevel-1  AP Transaction Entry
*		PayMethod(Seq 55) ValLevel-1  AP Unapproved Invoice Entry
*		PayMethod(Seq 30) ValLevel-1  AP Recurring Invoices
*		PayMethod(Seq 216)ValLevel-1  AP Payment Workfile
*
* Input:
*	@apco         AP Company
*	@vendorgrp	  Vendor Group
*	@vendor		  Vendor Code
*	@paymethod	  PayMethod for the transaction in question
*
* Output:
*   @msg          error message
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@apco bCompany = NULL,
 @vendorgrp bGroup = NULL, 
 @vendor bVendor = NULL,
 @paymethod char(1) = NULL,
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

--Validate apco, cmco and cmacct inputs
IF @apco IS NULL
BEGIN
	SELECT @msg = 'Missing AP Company'
	RETURN 1
END

--check setup information for Credit Service transactions
DECLARE @APCreditService tinyint,
		@APCSCMCo bCompany,
		@APCSCMAcct bCMAcct,
		@APCDAcctCode varchar(5), 
		@APCDCustID varchar(10), 
		@APCDCodeWord varchar(20),
		@APTCCo numeric(6,0),
		@APTCAcct numeric(10,0)

SELECT	@APCreditService = APCreditService,
		@APCSCMCo = CSCMCo,
		@APCSCMAcct = CSCMAcct,
		@APCDAcctCode = CDAcctCode, 
		@APCDCustID = CDCustID, 
		@APCDCodeWord = CDCodeWord,
		@APTCCo = TCCo,
		@APTCAcct = TCAcct
FROM dbo.bAPCO
WHERE APCo = @apco

IF @paymethod = 'S' --Pay Method is Credit Service
BEGIN
	--No Credit Service is selected in APCO
	IF @APCreditService = 0
	BEGIN
		SELECT @msg = 'No Credit Service has been selected for this AP Company '
		RETURN 1
	END

	DECLARE	@MissingCSCMAcctMsg varchar(50),
			@MissingCSSetupMsg varchar(50),
			@MissingCSEmailMsg varchar(50)
	
	--Credit Service CM Acct is missing in APCO
	IF @APCreditService <> 0 AND @APCSCMAcct IS NULL
	BEGIN
		SELECT @MissingCSCMAcctMsg = 'is missing Credit Service CM Acct'
	END

	--APCO is set up to use Credit Service Comdata but missing some of the Comdata setup
	IF @APCreditService = 1 
	BEGIN
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
		-- Check for the vendor email under credit service in VendMaster
		DECLARE @CreditServiceEmail varchar(60)
		SELECT	@CreditServiceEmail = CSEmail
		FROM dbo.bAPVM
		WHERE VendorGroup = @vendorgrp AND Vendor = @vendor
	
		IF @APCDAcctCode IS NULL OR @APCDCustID IS NULL OR @APCDCodeWord IS NULL
		BEGIN
			SELECT @MissingCSSetupMsg = 'Comdata setup is incomplete'
		END
		IF @CreditServiceEmail IS NULL
		BEGIN
			SELECT @MissingCSEmailMsg = 'Vendor Master is missing Credit Service email'
		END
	END

	--APCO is set up to use Credit Service T-Chek but missing some of the T-Chek setup
	IF @APCreditService = 2 AND (@APTCCo IS NULL OR @APTCAcct IS NULL)
	BEGIN
		SELECT @MissingCSSetupMsg = 'T-Chek setup is incomplete'
	END
	
	--Assemble error message if any
	IF @MissingCSCMAcctMsg IS NOT NULL OR @MissingCSSetupMsg IS NOT NULL OR @MissingCSEmailMsg IS NOT NULL
	BEGIN
		SELECT @msg = 'AP Company '
		
		--Missing credit service CMAcct information in AP Company
		IF @MissingCSCMAcctMsg IS NOT NULL
		BEGIN
			SELECT @msg = @msg + @MissingCSCMAcctMsg
		END
		--AND/OR
		--Missing credit service setup information for Comdata or T-Chek in AP Company
		IF @MissingCSSetupMsg IS NOT NULL 
		BEGIN
			IF @MissingCSCMAcctMsg IS NOT NULL 
			BEGIN
				SELECT @msg = @msg + ' and ' + @MissingCSSetupMsg
			END
			ELSE
			BEGIN
				SELECT @msg = @msg + @MissingCSSetupMsg
			END
		END
		--AND/OR
		--Missing credit service Email in AP Vendor Master
		IF @MissingCSEmailMsg IS NOT NULL
		BEGIN
			IF @MissingCSCMAcctMsg IS NOT NULL OR @MissingCSSetupMsg IS NOT NULL
			BEGIN
				SELECT @msg = @msg + ' and ' + @MissingCSEmailMsg
			END	
			ELSE
			BEGIN
				SELECT @msg = @MissingCSEmailMsg
			END
		END

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

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPPayMethodInfoCheck] TO [public]
GO
