SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARCM] as select a.* From bARCM a

GO
GRANT SELECT ON  [dbo].[ARCM] TO [public]
GRANT INSERT ON  [dbo].[ARCM] TO [public]
GRANT DELETE ON  [dbo].[ARCM] TO [public]
GRANT UPDATE ON  [dbo].[ARCM] TO [public]
GRANT SELECT ON  [dbo].[ARCM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARCM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARCM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARCM] TO [Viewpoint]
GO
