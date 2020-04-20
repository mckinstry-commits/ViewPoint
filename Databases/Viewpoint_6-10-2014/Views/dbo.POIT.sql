SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POIT] as select a.* From bPOIT a
GO
GRANT SELECT ON  [dbo].[POIT] TO [public]
GRANT INSERT ON  [dbo].[POIT] TO [public]
GRANT DELETE ON  [dbo].[POIT] TO [public]
GRANT UPDATE ON  [dbo].[POIT] TO [public]
GRANT SELECT ON  [dbo].[POIT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POIT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POIT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POIT] TO [Viewpoint]
GO
