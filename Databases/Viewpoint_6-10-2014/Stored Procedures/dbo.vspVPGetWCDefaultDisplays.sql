SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: Chris G 03/29/2011 B-02317
* MODIFIED BY: 
*
*
*
*
* Usage: Gets all the Display (default tabs) setup for the given user
*
* Input params:
*	@username
*
* Output params:
*	List of Displays
*
* Return code:
*	
************************************************************/
CREATE PROCEDURE [dbo].[vspVPGetWCDefaultDisplays]
	@username bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Its possible a user is assigned to 2 or more security groups
	-- that are all assigned to the same DisplayProfile (weee!) so
	-- use DISTINCT to get unique records.
    SELECT DISTINCT VPDisplaySecurityGroups.DisplayID, VPDisplayProfile.Name
		FROM VPDisplaySecurityGroups
			JOIN DDSU 
				ON DDSU.SecurityGroup = VPDisplaySecurityGroups.SecurityGroup
				AND DDSU.VPUserName = @username
			JOIN VPDisplayProfile
				ON VPDisplayProfile.KeyID = VPDisplaySecurityGroups.DisplayID
		ORDER BY VPDisplayProfile.Name
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetWCDefaultDisplays] TO [public]
GO
