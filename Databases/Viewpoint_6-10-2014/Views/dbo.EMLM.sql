SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMLM] as select a.* From bEMLM a
GO
GRANT SELECT ON  [dbo].[EMLM] TO [public]
GRANT INSERT ON  [dbo].[EMLM] TO [public]
GRANT DELETE ON  [dbo].[EMLM] TO [public]
GRANT UPDATE ON  [dbo].[EMLM] TO [public]
GRANT SELECT ON  [dbo].[EMLM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMLM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMLM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMLM] TO [Viewpoint]
GO
