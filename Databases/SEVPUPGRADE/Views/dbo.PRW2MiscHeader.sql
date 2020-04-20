SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRW2MiscHeader]
AS
SELECT     PRCo, TaxYear, State, LineNumber, Description, EDLType, EDLCode, KeyID
FROM         dbo.bPRW2MiscHeader


GO
GRANT SELECT ON  [dbo].[PRW2MiscHeader] TO [public]
GRANT INSERT ON  [dbo].[PRW2MiscHeader] TO [public]
GRANT DELETE ON  [dbo].[PRW2MiscHeader] TO [public]
GRANT UPDATE ON  [dbo].[PRW2MiscHeader] TO [public]
GO
