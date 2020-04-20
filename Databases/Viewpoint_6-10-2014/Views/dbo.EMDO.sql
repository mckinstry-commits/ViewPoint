SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDO] as select a.* From bEMDO a
GO
GRANT SELECT ON  [dbo].[EMDO] TO [public]
GRANT INSERT ON  [dbo].[EMDO] TO [public]
GRANT DELETE ON  [dbo].[EMDO] TO [public]
GRANT UPDATE ON  [dbo].[EMDO] TO [public]
GRANT SELECT ON  [dbo].[EMDO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDO] TO [Viewpoint]
GO
