SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployerFBTCodes]
AS
SELECT     PRCo, TaxYear, FBTType, EDLType, EDLCode, Category, Amount, KeyID, UniqueAttchID, Notes
FROM         dbo.vPRAUEmployerFBTCodes


GO
GRANT SELECT ON  [dbo].[PRAUEmployerFBTCodes] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerFBTCodes] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerFBTCodes] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerFBTCodes] TO [public]
GO
