SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREA] as select a.* from bPREA a 
GO
GRANT SELECT ON  [dbo].[PREA] TO [public]
GRANT INSERT ON  [dbo].[PREA] TO [public]
GRANT DELETE ON  [dbo].[PREA] TO [public]
GRANT UPDATE ON  [dbo].[PREA] TO [public]
GRANT SELECT ON  [dbo].[PREA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREA] TO [Viewpoint]
GO