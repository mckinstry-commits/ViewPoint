SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	AR 12/23/2010    
* MODIFIED:	
*
* Purpose:	Creating a separate proc to simplify vspDDFormSecurity
			Proc checks form security based on a users group

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE [dbo].[vspDDFormGroupSecurityCheck]
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

	-- get our access level of this user's group for a given form
	SET  @access = NULL
	SELECT  @access = MIN(Access)	-- get least restrictive access level
	FROM    dbo.vDDFS f WITH ( NOLOCK )
			JOIN dbo.vDDSU s WITH ( NOLOCK ) ON s.SecurityGroup = f.SecurityGroup
	WHERE   f.Co = @co
			AND f.Form = @form
			AND s.VPUserName = @user

	IF @access IN ( 0, 1 )	-- full access or tab level access
    BEGIN
		-- get record level permissions, use least restrictive option from any group the user
		-- belongs to at this access level 
		-- so a MAX will get a Y before an N, if no records MAX returns NULL so we convert to N         
		SELECT	@recupdate = ISNULL(MAX(RecUpdate),'N'), 
				@recdelete = ISNULL(MAX(RecDelete),'N'),
				@recadd = ISNULL(MAX(RecAdd),'N'),
				-- max security level is a 2
				@attachmentSecurityLevel = ISNULL(MAX(convert(int,AttachmentSecurityLevel)),-1)
        FROM    dbo.vDDFS f WITH ( NOLOCK )
					JOIN dbo.vDDSU s WITH ( NOLOCK ) ON s.SecurityGroup = f.SecurityGroup
        WHERE   f.Co =	@co
                AND f.Form = @form
                AND s.VPUserName = @user
                AND f.Access = @access
         
        SET  @errmsg = '@access is 0 or 1; multiple groups.'
    END
	ELSE IF @access = 2	-- access denied
    BEGIN
        SET  @errmsg = @user + ' has been denied access to the '
                + @form + ' form!'
	END
	ELSE IF @access IS NOT NULL -- should make a check constraint to disallow this
    BEGIN
        SELECT  @errmsg = 'Invalid access value assigned to the '
                + @form + ' form for ' + @user
                
        RAISERROR (@errmsg,15,8)
        RETURN (1)
    END
     -- if access is NULL don't return anything for error or output
    RETURN (0)
END


GO
GRANT EXECUTE ON  [dbo].[vspDDFormGroupSecurityCheck] TO [public]
GO
