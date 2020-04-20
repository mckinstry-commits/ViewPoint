SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCMenuTemplates
AS
SELECT     dbo.pMenuTemplates.*
FROM         dbo.pMenuTemplates

GO
GRANT SELECT ON  [dbo].[VCMenuTemplates] TO [public]
GRANT INSERT ON  [dbo].[VCMenuTemplates] TO [public]
GRANT DELETE ON  [dbo].[VCMenuTemplates] TO [public]
GRANT UPDATE ON  [dbo].[VCMenuTemplates] TO [public]
GRANT SELECT ON  [dbo].[VCMenuTemplates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCMenuTemplates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCMenuTemplates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCMenuTemplates] TO [Viewpoint]
GO
