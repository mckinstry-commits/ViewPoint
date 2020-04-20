SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspAPCOCreditServiceInfoCheck]

/***************************************************
* CREATED BY    : KK 01/25/12
* Modified by	: KK 02/09/12 - TK-Added check for PayMethods C and E to not allow CSCMAcct
*				  KK 02/28/12 - TK-Added check for EFT information (required APVM info & new params)
*				  KK 03/05/12 - TK-12973 Added validation for vendor email when paymethod is Comdata Credit service
*				  EN 04/04/12 - TK-12973 removed CMCo/CMAcct input params which are not needed
*				  KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
* Usage: Checks that all necessary information needed for valid AP payment transactions has been 
*		 entered in AP Company, AP Vendor, AP Entry, AP Unapproved, AP Recuring Inv, and/or AP Workfile
*		 before it get's into a batch.  
*
*		
*			
* Called from:	bspAPPBInitFromWorkFile (AP Pay Workfile - Create Pay Batch button )
*				bspAPPBEditInit (AP Pay Posting Initialize - Header)
*				bspAPPBInitialize (AP Pay Posting Initialize - File dropdown)
*				bspAPTHTransValInit (AP Pay Posting Initialize - Detail)
*
* Input:
*	@apco         AP Company
*	@cmco		  CM Company for the transaction in question
*	@cmacct		  CM Account for the transaction in question
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
 @cmco bCompany = NULL,
 @cmacct bCMAcct = NULL, 
 @vendorgrp bGroup = null, 
 @vendor bVendor = null,
 @paymethod char(1) = NULL,
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

--Validate apco, cmco and cmacct inputs
IF @apco IS NULL
BEGIN
	SELECT @msg = 'Missing AP Company '
	RETURN 1
END
IF @cmco IS NULL
BEGIN
	SELECT @msg = 'Missing CM Company '
	RETURN 1
END
IF @vendorgrp IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Group '
	RETURN 1
END

IF @vendor IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Code '
	RETURN 1
END

DECLARE	@returncode int,
		@paymethodvalerror varchar(255),
		@cmacctvalerror varchar(255)

--perform pay method validation
EXEC	@returncode = [dbo].[vspAPPayMethodInfoCheck]
		@apco,
		@vendorgrp,
		@vendor,
		@paymethod,
		@msg = @paymethodvalerror OUTPUT

IF @returncode = 0 SELECT @paymethodvalerror = NULL --value returned by validation is only important if an error was returned

--perform cm acct validation
EXEC	@returncode = [dbo].[vspAPCMAcctVal]
		@apco,
		@cmco,
		@cmacct,
		@paymethod,
		@msg = @cmacctvalerror OUTPUT

IF @returncode = 0 SELECT @cmacctvalerror = NULL --value returned by validation is only important if an error was returned

--return error when ...
--  cm acct error detected
IF @cmacctvalerror IS NOT NULL AND @paymethodvalerror IS NULL
BEGIN
	SELECT @msg = @cmacctvalerror
	RETURN 1
END
--  pay method error detected
ELSE IF @cmacctvalerror IS NULL AND @paymethodvalerror IS NOT NULL
BEGIN
	SELECT @msg = @paymethodvalerror
	RETURN 1
END
--  cm acct and pay method error detected (concatenate the error messages)
ELSE IF @cmacctvalerror IS NOT NULL AND @paymethodvalerror IS NOT NULL
BEGIN
	IF CHARINDEX(' and ', @paymethodvalerror) = 0
	BEGIN
		SELECT @msg = @cmacctvalerror + 'and ' + @paymethodvalerror
	END
	ELSE
	BEGIN
		SELECT @msg = @cmacctvalerror + ', ' + @paymethodvalerror
	END
	RETURN 1
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPCOCreditServiceInfoCheck] TO [public]
GO
