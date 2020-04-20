SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspAPPayMethodValForPayEdit]

/***************************************************
* CREATED BY    : EN 03/26/2012 TK-11585 Needed special validation for AP Payment Posting header
* Modified by	: KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
*
* Usage: Checks that all necessary information needed for valid AP Payment Method has been 
*		 entered in AP Company and AP Vendor and returns various possible warnings.
*		
*			
* Input:
*	@apco         AP Company
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
 @paymethod char(1) = NULL,
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

IF @paymethod = 'S' --Pay Method is Credit Service
BEGIN
	--Validate apco, cmco and cmacct inputs
	IF @apco IS NULL
	BEGIN
		SELECT @msg = 'Missing AP Company'
		RETURN 1
	END

	--check setup information for Credit Service transactions
	DECLARE @APCreditService tinyint,
			@APCSCMAcct bCMAcct,
			@APCDAcctCode varchar(5), 
			@APCDCustID varchar(10), 
			@APCDCodeWord varchar(20),
			@APTCCo numeric(6,0),
			@APTCAcct numeric(10,0)

	SELECT	@APCreditService = APCreditService,
			@APCSCMAcct = CSCMAcct,
			@APCDAcctCode = CDAcctCode, 
			@APCDCustID = CDCustID, 
			@APCDCodeWord = CDCodeWord,
			@APTCCo = TCCo,
			@APTCAcct = TCAcct
	FROM dbo.bAPCO
	WHERE APCo = @apco

	--No Credit Service is selected in APCO
	IF @APCreditService = 0
	BEGIN
		SELECT @msg = 'No Credit Service has been selected for this AP Company '
		RETURN 1
	END

	DECLARE	@MissingCSCMAcctMsg varchar(50),
			@MissingCSSetupMsg varchar(50)
	
	--validate for Credit Service CM Acct missing in APCO
	IF @APCreditService <> 0 AND @APCSCMAcct IS NULL
	BEGIN
		SELECT @MissingCSCMAcctMsg = 'is missing Credit Service CM Acct '
	END

	--validate for APCO set up to use Credit Service Comdata but missing some of the Comdata setup
	IF @APCreditService = 1 AND (@APCDAcctCode IS NULL OR @APCDCustID IS NULL OR @APCDCodeWord IS NULL)
	BEGIN
		SELECT @MissingCSSetupMsg = 'Comdata setup is incomplete '
	END

	--validate for APCO set up to use Credit Service T-Chek but missing some of the T-Chek setup
	IF @APCreditService = 2 AND (@APTCCo IS NULL OR @APTCAcct IS NULL)
	BEGIN
		SELECT @MissingCSSetupMsg = 'T-Chek setup is incomplete '
	END
	
	--Assemble error message if any
	IF @MissingCSCMAcctMsg IS NOT NULL AND @MissingCSSetupMsg IS NULL
	BEGIN
		SELECT @msg = 'AP Company ' + @MissingCSCMAcctMsg
		RETURN 1
	END
	IF @MissingCSCMAcctMsg IS NULL AND @MissingCSSetupMsg IS NOT NULL
	BEGIN
		SELECT @msg = 'AP Company ' + @MissingCSSetupMsg
		RETURN 1		
	END
	IF @MissingCSCMAcctMsg IS NOT NULL AND @MissingCSSetupMsg IS NOT NULL
	BEGIN
		SELECT @msg = 'AP Company ' + @MissingCSCMAcctMsg + 'and ' + @MissingCSSetupMsg
		RETURN 1
	END
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPPayMethodValForPayEdit] TO [public]
GO
