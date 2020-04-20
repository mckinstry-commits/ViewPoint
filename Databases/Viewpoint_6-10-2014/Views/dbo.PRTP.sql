SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTP] as select a.* From bPRTP a
GO
GRANT SELECT ON  [dbo].[PRTP] TO [public]
GRANT INSERT ON  [dbo].[PRTP] TO [public]
GRANT DELETE ON  [dbo].[PRTP] TO [public]
GRANT UPDATE ON  [dbo].[PRTP] TO [public]
GRANT SELECT ON  [dbo].[PRTP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTP] TO [Viewpoint]
GO
