SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APIN] as select a.* From bAPIN a
GO
GRANT SELECT ON  [dbo].[APIN] TO [public]
GRANT INSERT ON  [dbo].[APIN] TO [public]
GRANT DELETE ON  [dbo].[APIN] TO [public]
GRANT UPDATE ON  [dbo].[APIN] TO [public]
GRANT SELECT ON  [dbo].[APIN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APIN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APIN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APIN] TO [Viewpoint]
GO
