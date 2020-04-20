SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[APAUPayeeTaxPaymentATO] 
AS 
SELECT a.* FROM vAPAUPayeeTaxPaymentATO a


GO
GRANT SELECT ON  [dbo].[APAUPayeeTaxPaymentATO] TO [public]
GRANT INSERT ON  [dbo].[APAUPayeeTaxPaymentATO] TO [public]
GRANT DELETE ON  [dbo].[APAUPayeeTaxPaymentATO] TO [public]
GRANT UPDATE ON  [dbo].[APAUPayeeTaxPaymentATO] TO [public]
GRANT SELECT ON  [dbo].[APAUPayeeTaxPaymentATO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APAUPayeeTaxPaymentATO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APAUPayeeTaxPaymentATO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APAUPayeeTaxPaymentATO] TO [Viewpoint]
GO
