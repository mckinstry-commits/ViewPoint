
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[APAUPayerTaxPaymentATO] 
AS 
SELECT a.* FROM vAPAUPayerTaxPaymentATO a


GO

GRANT SELECT ON  [dbo].[APAUPayerTaxPaymentATO] TO [public]
GRANT INSERT ON  [dbo].[APAUPayerTaxPaymentATO] TO [public]
GRANT DELETE ON  [dbo].[APAUPayerTaxPaymentATO] TO [public]
GRANT UPDATE ON  [dbo].[APAUPayerTaxPaymentATO] TO [public]
GO
