SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvHRGender
AS
SELECT     'M' AS KeyField, 'Male' AS Description
UNION
SELECT     'F' AS KeyField, 'Female' AS Description


GO
GRANT SELECT ON  [dbo].[pvHRGender] TO [public]
GRANT INSERT ON  [dbo].[pvHRGender] TO [public]
GRANT DELETE ON  [dbo].[pvHRGender] TO [public]
GRANT UPDATE ON  [dbo].[pvHRGender] TO [public]
GRANT SELECT ON  [dbo].[pvHRGender] TO [VCSPortal]
GO
