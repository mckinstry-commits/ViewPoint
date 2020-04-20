SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUTSelect] 
/**************************************************
* Created: JonathanP 03/19/07
* Modified: 
* Adapated From: vspDDUCSelect
*
* Used to UPDATE the vDDUT table
*
* Inputs:
*	The user's username.
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
	@userID bVPUserName = null,
	@errmsg varchar(512) OUTPUT
	)

AS
SET NOCOUNT ON
	
	SELECT     VPUserName, ColorSchemeID, SmartCursorColor, ReqFieldColor
	FROM vDDUT
	WHERE VPUserName = @userID
	 
	RETURN

GO
GRANT EXECUTE ON  [dbo].[vspDDUTSelect] TO [public]
GO
