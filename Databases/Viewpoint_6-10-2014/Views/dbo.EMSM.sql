SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSM] as select a.* From bEMSM a
GO
GRANT SELECT ON  [dbo].[EMSM] TO [public]
GRANT INSERT ON  [dbo].[EMSM] TO [public]
GRANT DELETE ON  [dbo].[EMSM] TO [public]
GRANT UPDATE ON  [dbo].[EMSM] TO [public]
GRANT SELECT ON  [dbo].[EMSM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSM] TO [Viewpoint]
GO
