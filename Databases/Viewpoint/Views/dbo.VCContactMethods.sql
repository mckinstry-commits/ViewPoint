SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCContactMethods
AS
SELECT     dbo.pContactMethods.*
FROM         dbo.pContactMethods

GO
GRANT SELECT ON  [dbo].[VCContactMethods] TO [public]
GRANT INSERT ON  [dbo].[VCContactMethods] TO [public]
GRANT DELETE ON  [dbo].[VCContactMethods] TO [public]
GRANT UPDATE ON  [dbo].[VCContactMethods] TO [public]
GO
