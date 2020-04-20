SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspCreditServiceCMAcctVal]
/***********************************************************
* CREATED BY:   KK 04/03/12 - TK-12875 CMAcct Validation to use for Validation on CM Acct and return CMAcct Desc
* MODIFIED By : 
*				
*			
* USAGE: Validates CM Account through APCO and returns Credit Service CMAcct Description
*		 An error is returned if it is not a valid CSCMAcct
*
* INPUT PARAMETERS
*		APCo		AP Co get CMCo 
*		CMAcct		Account to validate against CMAC
*
* OUTPUT PARAMETERS
*		@CSCMAcct	Credit Service CM Account from APCO
*		@msg		Error message if error occurs otherwise Description of CMAcct
*
* RETURN VALUE
*		0			success
*		1			Failure
*****************************************************/ 
   
(@apco bCompany = 0, 
 @cmacct bCMAcct = NULL, 
 @CSCMAcctDesc bDesc OUTPUT,
 @msg varchar(60) OUTPUT)
 
AS
SET NOCOUNT ON
   
IF @apco IS NULL
BEGIN
	SELECT @msg = 'Missing AP Company!'
	RETURN 1
END  

IF @cmacct IS NULL
BEGIN
	SELECT @msg = 'Missing Credit Service CM Account!'
	RETURN 1
END    

SELECT DISTINCT @msg = a.Description
FROM CMAC a JOIN APCO b ON b.CMCo = a.CMCo
WHERE b.APCo = @apco AND a.CMAcct = @cmacct
   
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Credit Service CM Account not on file!'
	RETURN 1
END

SELECT @CSCMAcctDesc = Description 
FROM CMAC a JOIN APCO b ON b.CMCo = a.CMCo
WHERE b.APCo = @apco AND a.CMAcct = @cmacct


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspCreditServiceCMAcctVal] TO [public]
GO
