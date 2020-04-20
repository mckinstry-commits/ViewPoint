SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                       PROCEDURE [dbo].[vspDDGetTrustedConnectionLogin]
/**************************************************
* Created:  TEJ 01/10/2011
*
* When a user selects trusted connection, this stored procedure should be run
* to determine what the proper casing of the username should be. If the 
* username exists in multiple forms, we will check the case of the currently logged
* in user (suser_sname) and return that if it exists. Otherwise we will return the 
* username that was passed in.
*
* Inputs:  
*   @Username	    - Username passed in
*
* Output
*	@UsernameToUse  - The case sensitive username that should be used when logging in
*   @UserOccurences	- The number of case variations of the given username
*
****************************************************/
	(
		@Username bVPUserName = null,
		@UsernameToUse bVPUserName output,
		@UserOccurences int output 
	)
as
BEGIN
	-- Determine the existence of a the case insensitve form of the 
	SELECT @UserOccurences = COUNT(*) FROM DDUP WHERE LOWER(VPUserName) = LOWER(@Username)

	IF @UserOccurences = 1 
		Begin
			SELECT @UsernameToUse = VPUserName FROM DDUP WHERE LOWER(VPUserName) = LOWER(@Username)
		End
	ELSE
		Begin
			-- Most of our stored procedures use the following to compare based on username
			-- In the case we don't have a clear cut user in the database, use it for the default
			DECLARE @LoggedInUserOccurences As int 
			SELECT @LoggedInUserOccurences = COUNT(*) FROM DDUP WHERE VPUserName = SUSER_SNAME()
			
			If @LoggedInUserOccurences = 1
				Begin
					-- If the suser_sname() exists in the DDUP table database, we should use it
					SELECT @UsernameToUse = SUSER_SNAME()
				End
			Else
				Begin
					-- WHEN all else fails, just go with what they passed in.
					SELECT @UsernameToUse = @Username
				End
		End
END


GO
GRANT EXECUTE ON  [dbo].[vspDDGetTrustedConnectionLogin] TO [public]
GO
