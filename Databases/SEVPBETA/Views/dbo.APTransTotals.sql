SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.APTransTotals
AS
SELECT     a.Co, a.Mth, a.BatchId, a.BatchSeq, a.ExpMth, a.APTrans, SUM(d.DiscTaken) AS DiscAmt, SUM(d.Amount) AS CurrentAmt, SUM(d.Amount) 
                      - SUM(d.DiscTaken) AS NetAmt
FROM         dbo.bAPTB AS a WITH (nolock) LEFT OUTER JOIN
                      dbo.bAPDB AS d WITH (nolock) ON d.Co = a.Co AND d.Mth = a.Mth AND d.BatchId = a.BatchId AND d.BatchSeq = a.BatchSeq AND 
                      d.APTrans = a.APTrans AND d.ExpMth = a.ExpMth
GROUP BY a.Co, a.Mth, a.BatchId, a.BatchSeq, a.ExpMth, a.APTrans

GO
GRANT SELECT ON  [dbo].[APTransTotals] TO [public]
GRANT INSERT ON  [dbo].[APTransTotals] TO [public]
GRANT DELETE ON  [dbo].[APTransTotals] TO [public]
GRANT UPDATE ON  [dbo].[APTransTotals] TO [public]
GO
