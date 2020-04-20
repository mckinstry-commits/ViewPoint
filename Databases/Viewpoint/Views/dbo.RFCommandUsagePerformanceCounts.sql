SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFCommandUsagePerformanceCounts] as

select * from vRFCommandUsagePerformanceCounts


GO
GRANT SELECT ON  [dbo].[RFCommandUsagePerformanceCounts] TO [public]
GRANT INSERT ON  [dbo].[RFCommandUsagePerformanceCounts] TO [public]
GRANT DELETE ON  [dbo].[RFCommandUsagePerformanceCounts] TO [public]
GRANT UPDATE ON  [dbo].[RFCommandUsagePerformanceCounts] TO [public]
GO
