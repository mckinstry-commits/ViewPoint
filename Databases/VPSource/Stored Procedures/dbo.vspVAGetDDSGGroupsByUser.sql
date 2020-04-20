SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================    
-- Author:  Dave C, vspVAGetDDSGGroupsByUser
-- Create date: 6/4/09   
-- Description: Query returns the users in DDSG groups
-- =============================================    
CREATE PROCEDURE [dbo].[vspVAGetDDSGGroupsByUser]
(@group varchar(30))  
     
AS    
 
 SET NOCOUNT ON;    
     
SELECT	g.SecurityGroup,
		g.Name,
		g.GroupType,
		g.Description,
		u.VPUserName

FROM	DDSG g inner join DDSU u on g.SecurityGroup = u.SecurityGroup
 
WHERE	g.Name = @group
GO
GRANT EXECUTE ON  [dbo].[vspVAGetDDSGGroupsByUser] TO [public]
GO
