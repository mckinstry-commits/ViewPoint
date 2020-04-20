SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRUH] as select a.* From bPRUH a
GO
GRANT SELECT ON  [dbo].[PRUH] TO [public]
GRANT INSERT ON  [dbo].[PRUH] TO [public]
GRANT DELETE ON  [dbo].[PRUH] TO [public]
GRANT UPDATE ON  [dbo].[PRUH] TO [public]
GRANT SELECT ON  [dbo].[PRUH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRUH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRUH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRUH] TO [Viewpoint]
GO
