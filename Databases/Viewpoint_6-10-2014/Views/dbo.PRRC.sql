SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRC] as select a.* From bPRRC a
GO
GRANT SELECT ON  [dbo].[PRRC] TO [public]
GRANT INSERT ON  [dbo].[PRRC] TO [public]
GRANT DELETE ON  [dbo].[PRRC] TO [public]
GRANT UPDATE ON  [dbo].[PRRC] TO [public]
GRANT SELECT ON  [dbo].[PRRC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRRC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRRC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRRC] TO [Viewpoint]
GO
