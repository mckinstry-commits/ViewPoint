SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRC] as select a.* From bEMRC a
GO
GRANT SELECT ON  [dbo].[EMRC] TO [public]
GRANT INSERT ON  [dbo].[EMRC] TO [public]
GRANT DELETE ON  [dbo].[EMRC] TO [public]
GRANT UPDATE ON  [dbo].[EMRC] TO [public]
GRANT SELECT ON  [dbo].[EMRC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMRC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMRC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMRC] TO [Viewpoint]
GO
