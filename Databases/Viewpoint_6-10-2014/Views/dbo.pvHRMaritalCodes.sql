SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvHRMaritalCodes
AS
SELECT     'S' AS KeyField, 'S - Single' AS MaritalStatusDesc
UNION
SELECT     'M' AS KeyField, 'M - Married' AS Description
UNION
SELECT     'D' AS KeyField, 'D - Divorced' AS Description
UNION
SELECT     'O' AS KeyField, 'O - Other' AS Description


GO
GRANT SELECT ON  [dbo].[pvHRMaritalCodes] TO [public]
GRANT INSERT ON  [dbo].[pvHRMaritalCodes] TO [public]
GRANT DELETE ON  [dbo].[pvHRMaritalCodes] TO [public]
GRANT UPDATE ON  [dbo].[pvHRMaritalCodes] TO [public]
GRANT SELECT ON  [dbo].[pvHRMaritalCodes] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvHRMaritalCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvHRMaritalCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvHRMaritalCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvHRMaritalCodes] TO [Viewpoint]
GO
