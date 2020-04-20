SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRM] as select a.* From vRPRM a
GO
GRANT SELECT ON  [dbo].[RPRM] TO [public]
GRANT INSERT ON  [dbo].[RPRM] TO [public]
GRANT DELETE ON  [dbo].[RPRM] TO [public]
GRANT UPDATE ON  [dbo].[RPRM] TO [public]
GRANT SELECT ON  [dbo].[RPRM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRM] TO [Viewpoint]
GO
