SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORI] as select a.* From bPORI a
GO
GRANT SELECT ON  [dbo].[PORI] TO [public]
GRANT INSERT ON  [dbo].[PORI] TO [public]
GRANT DELETE ON  [dbo].[PORI] TO [public]
GRANT UPDATE ON  [dbo].[PORI] TO [public]
GRANT SELECT ON  [dbo].[PORI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PORI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PORI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PORI] TO [Viewpoint]
GO
