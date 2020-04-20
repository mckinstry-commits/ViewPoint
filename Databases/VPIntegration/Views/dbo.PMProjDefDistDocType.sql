SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PMProjDefDistDocType
AS
SELECT     DefaultKeyID, DocType
FROM         dbo.vPMProjDefDistDocType

GO
GRANT SELECT ON  [dbo].[PMProjDefDistDocType] TO [public]
GRANT INSERT ON  [dbo].[PMProjDefDistDocType] TO [public]
GRANT DELETE ON  [dbo].[PMProjDefDistDocType] TO [public]
GRANT UPDATE ON  [dbo].[PMProjDefDistDocType] TO [public]
GO
