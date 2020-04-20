SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspRPRLServerNameVal]
/***********************************************************
* CREATED BY: DK 07/22/2012
*
* USAGE:
*   Validates the RPRSServerName that is used on RPRL
*   pass in ServerName 
*   returns ErrMsg if any
* 

* OUTPUT PARAMETERS
*   @msg     Error message if invalid, 
* RETURN VALUE
*   0 Success
*   1 fail
*****************************************************/ 

@ServerName VARCHAR(50) = NULL, 
@msg VARCHAR(60) OUTPUT

AS
SET NOCOUNT ON
DECLARE @rcode INT


SELECT @rcode = 0

IF @ServerName IS NULL
BEGIN
	SELECT @msg = 'Missing ServerName!', @rcode = 1
	GOTO bspexit
END
ELSE 

IF NOT EXISTS(SELECT ServerName FROM RPRSServer WHERE ServerName = @ServerName) 
BEGIN
	SELECT @msg = 'Server Name does not exist!', @rcode = 1
	GOTO bspexit 

END 

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPRLServerNameVal] TO [public]
GO
