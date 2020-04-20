SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDUPValidateUserName]
/**********************************************
* Created: 01/25/2011 - Tom Jochums
*
* Validates Whether the username is valid and doesn't already exist
* Necessary to check the case insensitive user names for trusted connections
* We can't allow them to enter over one that already exists
*
* Inputs:
*	@VPUserName		User name to validate
*	
* Outputs:
*	@errmsg		    Error Message if it user name already exists
*
* Return code:
*	0 = success, 1 = failure
*
*************************************/

  	(@VPUserName bVPUserName = null, @errmsg VARCHAR(60) OUTPUT)
AS
BEGIN
	SET NOCOUNT ON	
	DECLARE @rcode INT
	SELECT @rcode = 0

	IF PATINDEX('%\%', @VPUserName) > 0
	BEGIN
		SELECT @errmsg = FullName
		FROM dbo.DDUP (NOLOCK)
		WHERE LOWER(VPUserName) = LOWER(@VPUserName)
		IF @@ROWCOUNT > 0
		BEGIN
				SELECT @errmsg = 'Domain User name already exists' , @rcode = 1
		END
	END

	RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vspDDUPValidateUserName] TO [public]
GO
