SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUTDelete] 
/**************************************************
* Created: JonathanP 03/19/07
* Modified: 
* Adapted from: vspDDUCDelete
*
* Used to delete a user''s color scheme.
*
* Inputs:
*	The user's username.
*	The color scheme ID.
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
	@userID bVPUserName = null, @colorSchemeID int = null
	--,@errmsg varchar(512) OUTPUT
	)

AS
SET NOCOUNT ON
	DECLARE @rcode int
	SELECT @rcode = 0	-- Default.

	IF @userID = null or @colorSchemeID = null
		SELECT --@errmsg = 'Missing input arguments @userid or @colorTheme.', 
			@rcode = 1

	DELETE FROM vDDUT
	WHERE VPUserName = @userID AND ColorSchemeID = @colorSchemeID
	 
	IF @@rowcount = 0
		SELECT --@errmsg = 'No rows deleted.', 
			@rcode = 1

	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUTDelete] TO [public]
GO
