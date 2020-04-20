SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAllowanceType] as select a.* From vPRAllowanceType a

GO
GRANT SELECT ON  [dbo].[PRAllowanceType] TO [public]
GRANT INSERT ON  [dbo].[PRAllowanceType] TO [public]
GRANT DELETE ON  [dbo].[PRAllowanceType] TO [public]
GRANT UPDATE ON  [dbo].[PRAllowanceType] TO [public]
GRANT SELECT ON  [dbo].[PRAllowanceType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAllowanceType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAllowanceType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAllowanceType] TO [Viewpoint]
GO
