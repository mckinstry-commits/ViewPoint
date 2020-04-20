SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	AR 12/23/2010    
* MODIFIED:	
*
* Purpose:	Creating a separate proc to simplify vspDDFormSecurity
			Proc checks form security based on a user

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE [dbo].[vspDDFormUserSecurityCheck]
	@co smallint = 0, 
	@form varchar(30),
	@user dbo.bVPUserName,
	@recupdate dbo.bYN  OUTPUT,
	@recdelete dbo.bYN OUTPUT,
	@recadd dbo.bYN OUTPUT,
	@attachmentSecurityLevel integer OUTPUT,
	@access tinyint OUTPUT,
	@errmsg varchar(512) OUTPUT
	
AS
BEGIN
	SET NOCOUNT ON;

	-- get our access level of this user's given form
	SELECT  @access = Access,
			@recadd = RecAdd,
			@recupdate = RecUpdate,
			@recdelete = RecDelete,
			@attachmentSecurityLevel = AttachmentSecurityLevel
	FROM    dbo.vDDFS WITH ( NOLOCK )
	WHERE   Co = @co
			AND Form = @form
			AND SecurityGroup = -1
			AND VPUserName = @user
        
	IF @@ROWCOUNT = 1 
		BEGIN
			IF @access IN ( 0, 1 ) -- full or tab level access
				BEGIN
					SELECT  @errmsg = '@access is 0 or 1.'	
				END
			ELSE IF @access = 2	-- form access denied
				BEGIN
					SELECT  @errmsg = @user + ' has been denied access to the '
							+ @form + ' form!'
				END
			ELSE
				BEGIN
					SELECT  @errmsg = 'Invalid access value assigned to the '
							+ @form + ' form for ' + @user
				END
		END
		
    RETURN (0)
END

GO
GRANT EXECUTE ON  [dbo].[vspDDFormUserSecurityCheck] TO [public]
GO
