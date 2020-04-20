SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JCPPCostTypesHdr] as select
		a.Co, a.Mth, a.BatchId
From JCPPCostTypes a
group by a.Co, a.Mth, a.BatchId

GO
GRANT SELECT ON  [dbo].[JCPPCostTypesHdr] TO [public]
GRANT INSERT ON  [dbo].[JCPPCostTypesHdr] TO [public]
GRANT DELETE ON  [dbo].[JCPPCostTypesHdr] TO [public]
GRANT UPDATE ON  [dbo].[JCPPCostTypesHdr] TO [public]
GRANT SELECT ON  [dbo].[JCPPCostTypesHdr] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPPCostTypesHdr] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPPCostTypesHdr] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPPCostTypesHdr] TO [Viewpoint]
GO
