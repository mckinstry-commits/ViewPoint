SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUCDelete] 
/**************************************************
* Created: JRK 05/24/06
* Modified: 
*
* Used to manage users' colors-by-company.
*
* Inputs:
*	The user's username.
*	The company.
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
	@userid bVPUserName = null, @co bCompany = null 
	--,@errmsg varchar(512) OUTPUT
	)

AS
	SET NOCOUNT ON
	DECLARE @rcode int
	SELECT @rcode = 0	-- Default.

	IF @userid = null or @co = null
		SELECT --@errmsg = 'Missing input arguments @userid or @co.', 
			@rcode = 1

	DELETE FROM DDUC 
	WHERE VPUserName = @userid AND Company = @co
	 
	IF @@rowcount = 0
		SELECT --@errmsg = 'No rows deleted.', 
			@rcode = 1

	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUCDelete] TO [public]
GO
