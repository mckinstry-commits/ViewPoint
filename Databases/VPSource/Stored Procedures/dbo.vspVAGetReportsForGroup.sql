SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetReportsForGroup]
/********************************
* Created:  2012-07-19 Chris Crewdson
* Modified: 
* 
* Returns all reports for which a given group influences access.
* 
* Input:
* @securitygroup - GroupID
* 
* Output:
* report IDs 
* 
*********************************/
(@securitygroup int = null)  
AS
BEGIN

SET NOCOUNT ON

SELECT ReportID
FROM RPRS
WHERE SecurityGroup = @securitygroup

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetReportsForGroup] TO [public]
GO
