SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetUsersInGroup]
/********************************
* Created: Narendra 2012-04-09
* Modified: 
* 
* Returns all VPUsers in given group.
* 
* Input:
* @securitygroup - GroupID
* 
* Output:
* VPUser names 
* 
*********************************/
(@securitygroup int = null)  
AS
BEGIN

SET NOCOUNT ON

SELECT VPUserName   
FROM dbo.DDSU   
WHERE SecurityGroup=@securitygroup

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUsersInGroup] TO [public]
GO
