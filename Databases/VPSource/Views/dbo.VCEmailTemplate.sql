SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VCEmailTemplate]
AS
SELECT     
    EmailTemplateID,
    Name,
    Description,
    FromAddress,
    ToAddress,
    CCAddress,
    BCCAddress,
    Subject,
    Body
FROM dbo.pEmailTemplate


GO
GRANT SELECT ON  [dbo].[VCEmailTemplate] TO [public]
GRANT INSERT ON  [dbo].[VCEmailTemplate] TO [public]
GRANT DELETE ON  [dbo].[VCEmailTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VCEmailTemplate] TO [public]
GO
