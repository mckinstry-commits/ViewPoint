SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWC] as select a.* From bPRWC a
GO
GRANT SELECT ON  [dbo].[PRWC] TO [public]
GRANT INSERT ON  [dbo].[PRWC] TO [public]
GRANT DELETE ON  [dbo].[PRWC] TO [public]
GRANT UPDATE ON  [dbo].[PRWC] TO [public]
GRANT SELECT ON  [dbo].[PRWC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRWC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRWC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRWC] TO [Viewpoint]
GO
