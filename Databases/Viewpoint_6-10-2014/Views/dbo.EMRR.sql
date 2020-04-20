SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRR] as select a.* From bEMRR a
GO
GRANT SELECT ON  [dbo].[EMRR] TO [public]
GRANT INSERT ON  [dbo].[EMRR] TO [public]
GRANT DELETE ON  [dbo].[EMRR] TO [public]
GRANT UPDATE ON  [dbo].[EMRR] TO [public]
GRANT SELECT ON  [dbo].[EMRR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMRR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMRR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMRR] TO [Viewpoint]
GO
