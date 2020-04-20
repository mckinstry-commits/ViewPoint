SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCE] as select a.* From bPRCE a
GO
GRANT SELECT ON  [dbo].[PRCE] TO [public]
GRANT INSERT ON  [dbo].[PRCE] TO [public]
GRANT DELETE ON  [dbo].[PRCE] TO [public]
GRANT UPDATE ON  [dbo].[PRCE] TO [public]
GRANT SELECT ON  [dbo].[PRCE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCE] TO [Viewpoint]
GO
