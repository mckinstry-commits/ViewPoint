SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMLookUpYesOrNo
AS
SELECT     CAST(1 AS BIT) AS KeyField, 'Yes' AS 'YNDescription'
UNION
SELECT     CAST(0 AS BIT) AS KeyField, 'No' AS 'YNDescription'


GO
GRANT SELECT ON  [dbo].[pvPMLookUpYesOrNo] TO [public]
GRANT INSERT ON  [dbo].[pvPMLookUpYesOrNo] TO [public]
GRANT DELETE ON  [dbo].[pvPMLookUpYesOrNo] TO [public]
GRANT UPDATE ON  [dbo].[pvPMLookUpYesOrNo] TO [public]
GRANT SELECT ON  [dbo].[pvPMLookUpYesOrNo] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMLookUpYesOrNo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMLookUpYesOrNo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMLookUpYesOrNo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMLookUpYesOrNo] TO [Viewpoint]
GO
