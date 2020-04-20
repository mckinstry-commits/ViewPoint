SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[PRAUEmployerFBTCategories]
AS
SELECT     dbo.vPRAUEmployerFBTCategories.*
FROM         dbo.vPRAUEmployerFBTCategories





GO
GRANT SELECT ON  [dbo].[PRAUEmployerFBTCategories] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerFBTCategories] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerFBTCategories] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBTCategories] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerFBTCategories] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerFBTCategories] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerFBTCategories] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBTCategories] TO [Viewpoint]
GO
