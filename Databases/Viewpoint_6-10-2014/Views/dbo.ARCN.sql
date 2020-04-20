SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARCN] as select a.* From bARCN a
GO
GRANT SELECT ON  [dbo].[ARCN] TO [public]
GRANT INSERT ON  [dbo].[ARCN] TO [public]
GRANT DELETE ON  [dbo].[ARCN] TO [public]
GRANT UPDATE ON  [dbo].[ARCN] TO [public]
GRANT SELECT ON  [dbo].[ARCN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARCN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARCN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARCN] TO [Viewpoint]
GO
