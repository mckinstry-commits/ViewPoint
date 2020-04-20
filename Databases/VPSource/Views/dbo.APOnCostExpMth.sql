SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APOnCostExpMth] as 
SELECT DISTINCT APCo,Mth
FROM dbo.APTH t
WHERE EXISTS
	(
		SELECT * 
		FROM dbo.APTL t2 
		WHERE t.APCo = t2.APCo AND t.Mth= t2.Mth AND t.APTrans = t2.APTrans 
			AND (t2.OnCostStatus=0 AND t2.SubjToOnCostYN='Y')
	)
GO
GRANT SELECT ON  [dbo].[APOnCostExpMth] TO [public]
GRANT INSERT ON  [dbo].[APOnCostExpMth] TO [public]
GRANT DELETE ON  [dbo].[APOnCostExpMth] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostExpMth] TO [public]
GO
