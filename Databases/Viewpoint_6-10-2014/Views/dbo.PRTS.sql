SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTS] as select a.* From bPRTS a

GO
GRANT SELECT ON  [dbo].[PRTS] TO [public]
GRANT INSERT ON  [dbo].[PRTS] TO [public]
GRANT DELETE ON  [dbo].[PRTS] TO [public]
GRANT UPDATE ON  [dbo].[PRTS] TO [public]
GRANT SELECT ON  [dbo].[PRTS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTS] TO [Viewpoint]
GO
