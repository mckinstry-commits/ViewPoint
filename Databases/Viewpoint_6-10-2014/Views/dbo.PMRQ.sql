SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMRQ] as select a.* From bPMRQ a
GO
GRANT SELECT ON  [dbo].[PMRQ] TO [public]
GRANT INSERT ON  [dbo].[PMRQ] TO [public]
GRANT DELETE ON  [dbo].[PMRQ] TO [public]
GRANT UPDATE ON  [dbo].[PMRQ] TO [public]
GRANT SELECT ON  [dbo].[PMRQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMRQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMRQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMRQ] TO [Viewpoint]
GO
