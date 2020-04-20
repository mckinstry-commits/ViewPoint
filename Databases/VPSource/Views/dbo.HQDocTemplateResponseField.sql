SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[HQDocTemplateResponseField]
AS
SELECT r.* FROM dbo.vHQDocTemplateResponseField AS r


GO
GRANT SELECT ON  [dbo].[HQDocTemplateResponseField] TO [public]
GRANT INSERT ON  [dbo].[HQDocTemplateResponseField] TO [public]
GRANT DELETE ON  [dbo].[HQDocTemplateResponseField] TO [public]
GRANT UPDATE ON  [dbo].[HQDocTemplateResponseField] TO [public]
GO
