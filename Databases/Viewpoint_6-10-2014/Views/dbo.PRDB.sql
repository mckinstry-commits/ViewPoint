SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDB] as select a.* From bPRDB a
GO
GRANT SELECT ON  [dbo].[PRDB] TO [public]
GRANT INSERT ON  [dbo].[PRDB] TO [public]
GRANT DELETE ON  [dbo].[PRDB] TO [public]
GRANT UPDATE ON  [dbo].[PRDB] TO [public]
GRANT SELECT ON  [dbo].[PRDB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDB] TO [Viewpoint]
GO
