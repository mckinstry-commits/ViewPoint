SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[APLBGrid]
AS
SELECT     TOP (100) PERCENT Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, Description, UM, GrossAmt, MiscAmt, MiscYN, TaxType, TaxAmt, 
                      Retainage, Discount, GrossAmt + (CASE MiscYN WHEN 'Y' THEN MiscAmt ELSE 0 END) + (CASE TaxType WHEN 2 THEN 0 ELSE TaxAmt END) 
                      AS Total, (GrossAmt + (CASE MiscYN WHEN 'Y' THEN MiscAmt ELSE 0 END) + (CASE TaxType WHEN 2 THEN 0 ELSE TaxAmt END)) 
                      - (Retainage + Discount) AS NetPayable
FROM         dbo.APLB WITH (nolock)
ORDER BY Co, Mth, BatchId, BatchSeq, APLine

GO
GRANT SELECT ON  [dbo].[APLBGrid] TO [public]
GRANT INSERT ON  [dbo].[APLBGrid] TO [public]
GRANT DELETE ON  [dbo].[APLBGrid] TO [public]
GRANT UPDATE ON  [dbo].[APLBGrid] TO [public]
GRANT SELECT ON  [dbo].[APLBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APLBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APLBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APLBGrid] TO [Viewpoint]
GO
