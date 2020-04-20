SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.HQOrganization

AS 

SELECT a.* FROM dbo.vHQOrganization AS a
GO
GRANT SELECT ON  [dbo].[HQOrganization] TO [public]
GRANT INSERT ON  [dbo].[HQOrganization] TO [public]
GRANT DELETE ON  [dbo].[HQOrganization] TO [public]
GRANT UPDATE ON  [dbo].[HQOrganization] TO [public]
GRANT SELECT ON  [dbo].[HQOrganization] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQOrganization] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQOrganization] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQOrganization] TO [Viewpoint]
GO
