SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFSceneUsagePerformanceCounts] as

select * from vRFSceneUsagePerformanceCounts


GO
GRANT SELECT ON  [dbo].[RFSceneUsagePerformanceCounts] TO [public]
GRANT INSERT ON  [dbo].[RFSceneUsagePerformanceCounts] TO [public]
GRANT DELETE ON  [dbo].[RFSceneUsagePerformanceCounts] TO [public]
GRANT UPDATE ON  [dbo].[RFSceneUsagePerformanceCounts] TO [public]
GO
