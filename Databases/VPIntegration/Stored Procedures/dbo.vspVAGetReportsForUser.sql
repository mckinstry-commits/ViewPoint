SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetReportsForUser]
/********************************
* Created:  2012-07-24 Chris Crewdson
* Modified: 
* 
* Returns all reports for which a given user has or is denied access.
* 
* Input:
* @username - VPUserName
* 
* Output:
* report IDs 
* 
*********************************/
(@username bVPUserName = null)  
AS
BEGIN

SET NOCOUNT ON

SELECT ReportID
FROM RPRS
WHERE VPUserName = @username

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetReportsForUser] TO [public]
GO
