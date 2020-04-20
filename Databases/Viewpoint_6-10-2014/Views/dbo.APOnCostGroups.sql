SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APOnCostGroups] as select a.* From vAPOnCostGroups a

GO
GRANT SELECT ON  [dbo].[APOnCostGroups] TO [public]
GRANT INSERT ON  [dbo].[APOnCostGroups] TO [public]
GRANT DELETE ON  [dbo].[APOnCostGroups] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostGroups] TO [public]
GRANT SELECT ON  [dbo].[APOnCostGroups] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APOnCostGroups] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APOnCostGroups] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APOnCostGroups] TO [Viewpoint]
GO
