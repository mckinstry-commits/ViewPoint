SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APOnCostAPTrans] as 
SELECT DISTINCT APCo,Mth,APTrans
FROM APTH t
WHERE EXISTS
	(
		SELECT * 
		FROM APTL t2 
		WHERE t.APCo = t2.APCo AND t.Mth= t2.Mth AND t.APTrans = t2.APTrans 
			AND (t2.OnCostStatus=0 AND t2.SubjToOnCostYN='Y')
	)







GO
GRANT SELECT ON  [dbo].[APOnCostAPTrans] TO [public]
GRANT INSERT ON  [dbo].[APOnCostAPTrans] TO [public]
GRANT DELETE ON  [dbo].[APOnCostAPTrans] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostAPTrans] TO [public]
GRANT SELECT ON  [dbo].[APOnCostAPTrans] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APOnCostAPTrans] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APOnCostAPTrans] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APOnCostAPTrans] TO [Viewpoint]
GO
