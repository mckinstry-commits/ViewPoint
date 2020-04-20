SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDMO
AS
SELECT     Mod, Title, Active, LicLevel, HelpKeyword
FROM         dbo.vDDMO

GO
GRANT SELECT ON  [dbo].[DDMO] TO [public]
GRANT INSERT ON  [dbo].[DDMO] TO [public]
GRANT DELETE ON  [dbo].[DDMO] TO [public]
GRANT UPDATE ON  [dbo].[DDMO] TO [public]
GRANT SELECT ON  [dbo].[DDMO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDMO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDMO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDMO] TO [Viewpoint]
GO
