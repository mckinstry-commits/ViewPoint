SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VCEmailField]
AS
SELECT     
    EmailFieldID,
    FieldKey,
    Description,
    Lookup,
    BuiltIn
FROM dbo.pEmailField


GO
GRANT SELECT ON  [dbo].[VCEmailField] TO [public]
GRANT INSERT ON  [dbo].[VCEmailField] TO [public]
GRANT DELETE ON  [dbo].[VCEmailField] TO [public]
GRANT UPDATE ON  [dbo].[VCEmailField] TO [public]
GO
