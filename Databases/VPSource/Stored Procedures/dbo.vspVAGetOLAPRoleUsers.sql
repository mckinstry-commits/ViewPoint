SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspVAGetOLAPRoleUsers
-- Create date: 4/22/2008
-- Description:	Gets the Windows User Names and Group Name
--				for all users in data security groups
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetOLAPRoleUsers]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select Name, WindowsUserName 
	from DDSU u with (nolock) Join DDUP p with (nolock) on u.VPUserName = p.VPUserName
	Join DDSG g with (nolock) on u.SecurityGroup = g.SecurityGroup
	where WindowsUserName is not null and GroupType = 0

END

GO
GRANT EXECUTE ON  [dbo].[vspVAGetOLAPRoleUsers] TO [public]
GO
