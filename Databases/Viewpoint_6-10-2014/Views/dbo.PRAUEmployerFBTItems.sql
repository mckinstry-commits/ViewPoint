SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[PRAUEmployerFBTItems]
AS
SELECT     dbo.vPRAUEmployerFBTItems.*
FROM         dbo.vPRAUEmployerFBTItems




GO
GRANT SELECT ON  [dbo].[PRAUEmployerFBTItems] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerFBTItems] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerFBTItems] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBTItems] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerFBTItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerFBTItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerFBTItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBTItems] TO [Viewpoint]
GO
