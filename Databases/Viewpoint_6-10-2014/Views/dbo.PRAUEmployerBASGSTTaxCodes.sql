SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployerBASGSTTaxCodes]
AS 
SELECT * FROM dbo.[vPRAUEmployerBASGSTTaxCodes]




GO
GRANT SELECT ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerBASGSTTaxCodes] TO [Viewpoint]
GO
