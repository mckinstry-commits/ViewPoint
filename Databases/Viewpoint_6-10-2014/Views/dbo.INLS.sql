SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INLS] as select a.* From bINLS a
GO
GRANT SELECT ON  [dbo].[INLS] TO [public]
GRANT INSERT ON  [dbo].[INLS] TO [public]
GRANT DELETE ON  [dbo].[INLS] TO [public]
GRANT UPDATE ON  [dbo].[INLS] TO [public]
GRANT SELECT ON  [dbo].[INLS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INLS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INLS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INLS] TO [Viewpoint]
GO
