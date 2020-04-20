SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPD] as select a.* From bPMPD a
GO
GRANT SELECT ON  [dbo].[PMPD] TO [public]
GRANT INSERT ON  [dbo].[PMPD] TO [public]
GRANT DELETE ON  [dbo].[PMPD] TO [public]
GRANT UPDATE ON  [dbo].[PMPD] TO [public]
GRANT SELECT ON  [dbo].[PMPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPD] TO [Viewpoint]
GO
