SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PROS] as select a.* From bPROS a
GO
GRANT SELECT ON  [dbo].[PROS] TO [public]
GRANT INSERT ON  [dbo].[PROS] TO [public]
GRANT DELETE ON  [dbo].[PROS] TO [public]
GRANT UPDATE ON  [dbo].[PROS] TO [public]
GRANT SELECT ON  [dbo].[PROS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PROS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PROS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PROS] TO [Viewpoint]
GO
