SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTE] as select a.* From bPRTE a
GO
GRANT SELECT ON  [dbo].[PRTE] TO [public]
GRANT INSERT ON  [dbo].[PRTE] TO [public]
GRANT DELETE ON  [dbo].[PRTE] TO [public]
GRANT UPDATE ON  [dbo].[PRTE] TO [public]
GRANT SELECT ON  [dbo].[PRTE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTE] TO [Viewpoint]
GO
