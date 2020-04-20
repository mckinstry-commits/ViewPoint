SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[APOnCostGroupTypes] as select a.* From vAPOnCostGroupTypes a




GO
GRANT SELECT ON  [dbo].[APOnCostGroupTypes] TO [public]
GRANT INSERT ON  [dbo].[APOnCostGroupTypes] TO [public]
GRANT DELETE ON  [dbo].[APOnCostGroupTypes] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostGroupTypes] TO [public]
GO
