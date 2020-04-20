SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VCRoles]
AS
SELECT * --RoleID, Name, Description, Active, Static, ClientModified
FROM dbo.pRoles

GO
GRANT SELECT ON  [dbo].[VCRoles] TO [public]
GRANT INSERT ON  [dbo].[VCRoles] TO [public]
GRANT DELETE ON  [dbo].[VCRoles] TO [public]
GRANT UPDATE ON  [dbo].[VCRoles] TO [public]
GO
