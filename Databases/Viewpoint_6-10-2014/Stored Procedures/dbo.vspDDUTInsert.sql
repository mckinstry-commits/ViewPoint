SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUTInsert] 
/**************************************************
* Created: JonathanP 03/19/07
* Modified: 
* Adapated from: vspDDUCInsert
*
* Used to insert a user's color theme in DDUT.
*
* Inputs:
*	The user's username.
*	The color scheme ID.
*	Color parameters.  All are nullable.
*
* Output:
*	resultset of users' colors, by company.
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(
	@userID bVPUserName = null, @colorSchemeID INT = null, @smartCursorColor INT = null, 
	@reqFieldColor int = null	
	--,@errmsg varchar(512) OUTPUT
	)

AS
	SET NOCOUNT ON
	DECLARE @rcode int
	SELECT @rcode = 0	-- Default.

	IF @userID = null or @colorSchemeID = null
		SELECT --@errmsg = 'Missing input arguments @userID or @colorSchemeID.', 
			@rcode = 1

	INSERT INTO vDDUT
     (VPUserName, ColorSchemeID, SmartCursorColor, ReqFieldColor)
	VALUES (@userID, @colorSchemeID, @smartCursorColor, @reqFieldColor)

	IF @@rowcount = 0
		SELECT --@errmsg = 'No rows inserted.', 
			@rcode = 1
	 
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUTInsert] TO [public]
GO
