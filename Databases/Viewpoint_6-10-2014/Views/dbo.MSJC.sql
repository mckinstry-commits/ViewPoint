SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSJC] as select a.* From bMSJC a
GO
GRANT SELECT ON  [dbo].[MSJC] TO [public]
GRANT INSERT ON  [dbo].[MSJC] TO [public]
GRANT DELETE ON  [dbo].[MSJC] TO [public]
GRANT UPDATE ON  [dbo].[MSJC] TO [public]
GRANT SELECT ON  [dbo].[MSJC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSJC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSJC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSJC] TO [Viewpoint]
GO
