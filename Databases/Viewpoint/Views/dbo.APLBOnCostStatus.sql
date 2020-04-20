SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APLBOnCostStatus] as 
SELECT DISTINCT
	a.Co,
	a.Mth,
	a.BatchId,
	a.BatchSeq,
	a.APLine,
	l.OnCostStatus
FROM dbo.APLB a
JOIN dbo.APHB b
ON a.Co=b.Co AND a.Mth=b.Mth AND a.BatchId=b.BatchId AND a.BatchSeq=b.BatchSeq
LEFT OUTER JOIN dbo.APTL l 
ON b.Co=l.APCo AND b.Mth=l.Mth AND b.APTrans=l.APTrans AND a.APLine=l.APLine

GO
GRANT SELECT ON  [dbo].[APLBOnCostStatus] TO [public]
GRANT INSERT ON  [dbo].[APLBOnCostStatus] TO [public]
GRANT DELETE ON  [dbo].[APLBOnCostStatus] TO [public]
GRANT UPDATE ON  [dbo].[APLBOnCostStatus] TO [public]
GO
