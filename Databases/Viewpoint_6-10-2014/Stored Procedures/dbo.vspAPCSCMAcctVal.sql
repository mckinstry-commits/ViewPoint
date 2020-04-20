SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPCSCMAcctVal    Script Date: 8/28/99 9:32:36 AM ******/
CREATE   proc [dbo].[vspAPCSCMAcctVal]
/***********************************************************
* CREATED BY: EN   4/28/2012 B-09201
* MODIFIED By : 
*
* USAGE:
* Modified from vspAPCSCMAcctVal but needed to return a message specific to Credit Service CM Account
* if it is not found in CMAC
*
* INPUT PARAMETERS
*   CMCo		CM Co to validate against
*   CSCMAcct	Credit Service CM Account to validate
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of CMAcct
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@CMCo bCompany = 0, 
 @CSCMAcct bCMAcct = NULL,  
 @msg varchar(60) OUTPUT)
 
AS
SET NOCOUNT ON

IF @CMCo IS NULL
BEGIN
	SELECT @msg = 'Missing CM Company!'
	RETURN 1
END

IF @CSCMAcct IS NULL
BEGIN
	SELECT @msg = 'Missing CM Account!'
	RETURN 1
END

SELECT @msg = [Description] 
FROM dbo.CMAC 
WHERE CMCo = @CMCo AND CMAcct = @CSCMAcct

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Credit Service CM Account not on file.'
	RETURN 1
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspAPCSCMAcctVal] TO [public]
GO
