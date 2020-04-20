SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[APOnCostGroupsForLookup] as 
SELECT DISTINCT APCo, GroupID,Description 
FROM vAPOnCostGroups 

GO
GRANT SELECT ON  [dbo].[APOnCostGroupsForLookup] TO [public]
GRANT INSERT ON  [dbo].[APOnCostGroupsForLookup] TO [public]
GRANT DELETE ON  [dbo].[APOnCostGroupsForLookup] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostGroupsForLookup] TO [public]
GRANT SELECT ON  [dbo].[APOnCostGroupsForLookup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APOnCostGroupsForLookup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APOnCostGroupsForLookup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APOnCostGroupsForLookup] TO [Viewpoint]
GO
