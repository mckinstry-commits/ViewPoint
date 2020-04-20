SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VCEmailTemplateField]
AS
SELECT
    EmailTemplateFieldID,
    EmailTemplateID,
    EmailFieldID
FROM dbo.pEmailTemplateField


GO
GRANT SELECT ON  [dbo].[VCEmailTemplateField] TO [public]
GRANT INSERT ON  [dbo].[VCEmailTemplateField] TO [public]
GRANT DELETE ON  [dbo].[VCEmailTemplateField] TO [public]
GRANT UPDATE ON  [dbo].[VCEmailTemplateField] TO [public]
GRANT SELECT ON  [dbo].[VCEmailTemplateField] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCEmailTemplateField] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCEmailTemplateField] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCEmailTemplateField] TO [Viewpoint]
GO
