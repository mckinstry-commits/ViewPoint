SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
--				Matt Pement 11/30/09 - #136176 - Changed to return the SecurityGroup Id as well
-- Create date: 5/14/07
-- Description:	Returns the names of all the security groups
-- =============================================
CREATE PROCEDURE [dbo].[vspVASecurityGroups] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select Name, SecurityGroup from DDSG WHERE [GroupType] = 1
END


GO
GRANT EXECUTE ON  [dbo].[vspVASecurityGroups] TO [public]
GO
