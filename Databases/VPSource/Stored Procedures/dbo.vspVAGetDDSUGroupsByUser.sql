SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================    
-- Author:  Chris Crewdson
-- Created: 2012-07-23
-- Description: Query returns the groups a user is assigned to
-- =============================================    
CREATE PROCEDURE [dbo].[vspVAGetDDSUGroupsByUser]
(@username bVPUserName)
AS
 
 SET NOCOUNT ON;    
     
SELECT  u.SecurityGroup
FROM    DDSU u
WHERE   u.VPUserName = @username
GO
GRANT EXECUTE ON  [dbo].[vspVAGetDDSUGroupsByUser] TO [public]
GO
