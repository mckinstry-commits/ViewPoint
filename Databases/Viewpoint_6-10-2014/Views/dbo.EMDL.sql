SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDL] as select a.* From bEMDL a
GO
GRANT SELECT ON  [dbo].[EMDL] TO [public]
GRANT INSERT ON  [dbo].[EMDL] TO [public]
GRANT DELETE ON  [dbo].[EMDL] TO [public]
GRANT UPDATE ON  [dbo].[EMDL] TO [public]
GRANT SELECT ON  [dbo].[EMDL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDL] TO [Viewpoint]
GO
