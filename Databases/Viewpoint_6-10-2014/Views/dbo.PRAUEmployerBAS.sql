SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE VIEW [dbo].[PRAUEmployerBAS]
AS 
SELECT * FROM dbo.[vPRAUEmployerBAS]


GO
GRANT SELECT ON  [dbo].[PRAUEmployerBAS] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerBAS] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerBAS] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerBAS] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerBAS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerBAS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerBAS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerBAS] TO [Viewpoint]
GO
