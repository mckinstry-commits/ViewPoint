SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE VIEW [dbo].[PRAUEmployerFBT] 
AS 
SELECT * FROM dbo.[vPRAUEmployerFBT]












GO
GRANT SELECT ON  [dbo].[PRAUEmployerFBT] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerFBT] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerFBT] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBT] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerFBT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerFBT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerFBT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBT] TO [Viewpoint]
GO
