SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDH] as select a.* From bPMDH a
GO
GRANT SELECT ON  [dbo].[PMDH] TO [public]
GRANT INSERT ON  [dbo].[PMDH] TO [public]
GRANT DELETE ON  [dbo].[PMDH] TO [public]
GRANT UPDATE ON  [dbo].[PMDH] TO [public]
GRANT SELECT ON  [dbo].[PMDH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDH] TO [Viewpoint]
GO
