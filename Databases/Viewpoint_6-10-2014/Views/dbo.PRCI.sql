SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCI] as select a.* From bPRCI a
GO
GRANT SELECT ON  [dbo].[PRCI] TO [public]
GRANT INSERT ON  [dbo].[PRCI] TO [public]
GRANT DELETE ON  [dbo].[PRCI] TO [public]
GRANT UPDATE ON  [dbo].[PRCI] TO [public]
GRANT SELECT ON  [dbo].[PRCI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCI] TO [Viewpoint]
GO
