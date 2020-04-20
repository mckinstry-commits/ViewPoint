SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRUR] as select a.* From bPRUR a
GO
GRANT SELECT ON  [dbo].[PRUR] TO [public]
GRANT INSERT ON  [dbo].[PRUR] TO [public]
GRANT DELETE ON  [dbo].[PRUR] TO [public]
GRANT UPDATE ON  [dbo].[PRUR] TO [public]
GRANT SELECT ON  [dbo].[PRUR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRUR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRUR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRUR] TO [Viewpoint]
GO
