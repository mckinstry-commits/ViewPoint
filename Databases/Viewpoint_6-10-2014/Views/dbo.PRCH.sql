SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCH] as select a.* From bPRCH a
GO
GRANT SELECT ON  [dbo].[PRCH] TO [public]
GRANT INSERT ON  [dbo].[PRCH] TO [public]
GRANT DELETE ON  [dbo].[PRCH] TO [public]
GRANT UPDATE ON  [dbo].[PRCH] TO [public]
GRANT SELECT ON  [dbo].[PRCH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCH] TO [Viewpoint]
GO
