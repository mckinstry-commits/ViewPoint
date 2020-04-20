SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRDeductionGroup] as select a.* From bPRDeductionGroup a

GO
GRANT SELECT ON  [dbo].[PRDeductionGroup] TO [public]
GRANT INSERT ON  [dbo].[PRDeductionGroup] TO [public]
GRANT DELETE ON  [dbo].[PRDeductionGroup] TO [public]
GRANT UPDATE ON  [dbo].[PRDeductionGroup] TO [public]
GRANT SELECT ON  [dbo].[PRDeductionGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDeductionGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDeductionGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDeductionGroup] TO [Viewpoint]
GO
