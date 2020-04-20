SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[PRAUEmployerBASAmounts]
AS 
SELECT * FROM dbo.[vPRAUEmployerBASAmounts]






GO
GRANT SELECT ON  [dbo].[PRAUEmployerBASAmounts] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerBASAmounts] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerBASAmounts] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerBASAmounts] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerBASAmounts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerBASAmounts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerBASAmounts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerBASAmounts] TO [Viewpoint]
GO
