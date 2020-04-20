SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUTUpdate] 
/**************************************************
* Created: JonathanP 03/19/07
* Modified: 
* Adapated from: vspDDUCUpate
*
* Used to UPDATE the vDDUT table
*
* Inputs:
*	The user's username.
*	The color scheme.
*	Color parameters.  All are nullable.
*
* Output:
*	resultset of users' colors, by color scheme.
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(
	@userID bVPUserName = null, @colorSchemeID int = null, 
	@smartCursorColor int = null, @reqFieldColor int = null
	--,@errmsg varchar(512) OUTPUT
	)

AS
	SET NOCOUNT ON
	DECLARE @rcode int
	SELECT @rcode = 0	-- Default.

	IF @userID = null or @colorSchemeID = null
		SELECT --@errmsg = 'Missing input arguments @userid or @colorSchemeID.', 
			@rcode = 1

	UPDATE vDDUT SET
		SmartCursorColor = @smartCursorColor, ReqFieldColor = @reqFieldColor
	WHERE VPUserName = @userID AND ColorSchemeID = @colorSchemeID

	IF @@rowcount = 0
		SELECT --@errmsg = 'No rows updated.', 
			@rcode = 1
	 
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUTUpdate] TO [public]
GO
