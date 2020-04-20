SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDE] as select a.* From bEMDE a
GO
GRANT SELECT ON  [dbo].[EMDE] TO [public]
GRANT INSERT ON  [dbo].[EMDE] TO [public]
GRANT DELETE ON  [dbo].[EMDE] TO [public]
GRANT UPDATE ON  [dbo].[EMDE] TO [public]
GRANT SELECT ON  [dbo].[EMDE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDE] TO [Viewpoint]
GO
