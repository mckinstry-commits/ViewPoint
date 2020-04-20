SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQMC] as select a.* From bHQMC a
GO
GRANT SELECT ON  [dbo].[HQMC] TO [public]
GRANT INSERT ON  [dbo].[HQMC] TO [public]
GRANT DELETE ON  [dbo].[HQMC] TO [public]
GRANT UPDATE ON  [dbo].[HQMC] TO [public]
GRANT SELECT ON  [dbo].[HQMC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQMC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQMC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQMC] TO [Viewpoint]
GO
