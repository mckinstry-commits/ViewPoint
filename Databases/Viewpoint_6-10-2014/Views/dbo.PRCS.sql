SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCS] as select a.* From bPRCS a
GO
GRANT SELECT ON  [dbo].[PRCS] TO [public]
GRANT INSERT ON  [dbo].[PRCS] TO [public]
GRANT DELETE ON  [dbo].[PRCS] TO [public]
GRANT UPDATE ON  [dbo].[PRCS] TO [public]
GRANT SELECT ON  [dbo].[PRCS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCS] TO [Viewpoint]
GO
