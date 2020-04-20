SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWI] as select a.* From bPRWI a
GO
GRANT SELECT ON  [dbo].[PRWI] TO [public]
GRANT INSERT ON  [dbo].[PRWI] TO [public]
GRANT DELETE ON  [dbo].[PRWI] TO [public]
GRANT UPDATE ON  [dbo].[PRWI] TO [public]
GRANT SELECT ON  [dbo].[PRWI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRWI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRWI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRWI] TO [Viewpoint]
GO
