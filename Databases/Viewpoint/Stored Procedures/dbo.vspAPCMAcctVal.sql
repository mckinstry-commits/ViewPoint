SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPCMAcctVal  Script Date: 8/28/99 9:32:36 AM ******/
CREATE   proc [dbo].[vspAPCMAcctVal]
/***************************************************************************
* CREATED BY:	KK 02/09/12
* MODIFIED By : KK 03/02/12 - Moved validation specific to Pay method to a new sp vspAPPayMethodInfoCheck
*				EN 03/16/12 - more stuff (wrapped @APCSCMAcct in ISNULL() to still trigger error message if APCO_CSCMAcct is empty)
*
* USAGE:	Validates CM Account to make sure it is accessible through CMAC
*			An error is returned if any of the following occurs, else Dexcription
*
* DDFI Validation Procedure for:
*			CMAcct (seq 62)  ValLevel-1	AP Transaction Entry
*			CMAcct (Seq 60)  ValLevel-1	AP Unapproved Invoice Entry
*			CMAcct (seq 45)  ValLevel-1	AP Recurring Invoices
*			CMAcct (seq 217) ValLevel-1	AP Payment Workfile
*			CMAcct (seq 30)  ValLevel-3 AP EFT
*			CMAcct (seq 15)  ValLevel-3 AP ChkPrnt
*
* INPUT PARAMETERS
*	CMCo		CM Co to validate agains 
*   CMAcct		Account to validate
*	PayMethod	Pay method needed to verify the correct CM Account is being used
*
* OUTPUT PARAMETERS
*   @msg		error message if error occurs
*
* RETURN VALUE
*   0			success
*   1			Failure
******************************************************************************/ 
   
(@apco bCompany = 0,
 @cmco bCompany = 0, 
 @cmacct bCMAcct = NULL, 
 @paymethod char(1) = NULL,
 @msg varchar(255) OUTPUT)

AS 
SET NOCOUNT ON

--check setup information for Credit Service transactions
DECLARE @APCSCMAcct bCMAcct
SELECT	@APCSCMAcct = CSCMAcct
FROM dbo.bAPCO
WHERE APCo = @apco

IF @cmco IS NULL
BEGIN
	SELECT @msg = 'Missing CM Company!'
	RETURN 1
END

IF @cmacct IS NULL
BEGIN
	SELECT @msg = 'Missing CM Account!'
	RETURN 1
END

--Check for existance of CM Account
SELECT @msg = Description 
FROM CMAC
WHERE CMCo = @cmco AND CMAcct = @cmacct

IF @@rowcount = 0
BEGIN
	SELECT @msg = 'CM Account not on file '
	RETURN 1
END

IF @paymethod = 'S' --Pay Method is Credit Service
BEGIN
	--CMAcct on the tran does not match APCO CSCMAcct
	IF ISNULL(@APCSCMAcct,'') <> @cmacct 
	BEGIN
		SELECT @msg = 'Credit Service CM Acct must match the Credit Service CM Acct in AP Company '
		RETURN 1
	END
END
ELSE --Pay Method is Check or EFT	
BEGIN
	--Transaction has a CSCMAcct and should not
	IF @APCSCMAcct = @cmacct 
	BEGIN
		SELECT @msg = 'You cannot use a Credit Service CM Acct with this pay method '
		RETURN 1
	END	
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPCMAcctVal] TO [public]
GO
