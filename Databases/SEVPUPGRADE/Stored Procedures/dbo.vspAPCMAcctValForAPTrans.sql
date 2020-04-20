SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPCMAcctValForAPTrans  Script Date: 8/28/99 9:32:36 AM ******/
CREATE   proc [dbo].[vspAPCMAcctValForAPTrans]
/***************************************************************************
* CREATED BY:	EN 05/02/12
* MODIFIED By : 
*
* USAGE:	Validates CM Account using the Pay Method of the specified transaction.
*			Specifically needed when adding CMAcct to Credit Service transactions that have none.
*			An error is returned if any of the following occurs, else Description
*
* INPUT PARAMETERS
*	@apco		AP Company
*	@cmco		CM Co to validate agains 
*   @cmacct		Account to validate
*	@expmth		Expense month of AP Transaction
*	@aptrans	AP Transaction #
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
 @expmth bMonth = NULL, 
 @aptrans bTrans = NULL,
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

IF @expmth IS NULL
BEGIN
	SELECT @msg = 'Missing Expense Month!'
	RETURN 1
END

IF @aptrans IS NULL
BEGIN
	SELECT @msg = 'Missing AP Transaction number!'
	RETURN 1
END

--Determine pay method to use in CM Account validation
DECLARE @paymethod char(1)

SELECT @paymethod = PayMethod 
FROM dbo.bAPTH
WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'AP Transaction not on file '
	RETURN 1
END

--Execute CM Account validation
DECLARE	@return_value int

EXEC	@return_value = [dbo].[vspAPCMAcctVal]
		@apco = @apco,
		@cmco = @cmco,
		@cmacct = @cmacct,
		@paymethod = @paymethod,
		@msg = @msg OUTPUT
		
IF @return_value <> 0 RETURN @return_value


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPCMAcctValForAPTrans] TO [public]
GO
