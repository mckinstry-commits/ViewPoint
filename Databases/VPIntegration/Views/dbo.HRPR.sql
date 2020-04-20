SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRPR] as select a.* From bHRPR a

GO
GRANT SELECT ON  [dbo].[HRPR] TO [public]
GRANT INSERT ON  [dbo].[HRPR] TO [public]
GRANT DELETE ON  [dbo].[HRPR] TO [public]
GRANT UPDATE ON  [dbo].[HRPR] TO [public]
GO
