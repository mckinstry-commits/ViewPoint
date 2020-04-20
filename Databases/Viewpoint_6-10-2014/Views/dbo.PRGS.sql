SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGS] as select a.* From bPRGS a
GO
GRANT SELECT ON  [dbo].[PRGS] TO [public]
GRANT INSERT ON  [dbo].[PRGS] TO [public]
GRANT DELETE ON  [dbo].[PRGS] TO [public]
GRANT UPDATE ON  [dbo].[PRGS] TO [public]
GRANT SELECT ON  [dbo].[PRGS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRGS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRGS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRGS] TO [Viewpoint]
GO
