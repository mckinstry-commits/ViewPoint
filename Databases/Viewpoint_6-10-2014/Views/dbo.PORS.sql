SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORS] as select a.* From bPORS a
GO
GRANT SELECT ON  [dbo].[PORS] TO [public]
GRANT INSERT ON  [dbo].[PORS] TO [public]
GRANT DELETE ON  [dbo].[PORS] TO [public]
GRANT UPDATE ON  [dbo].[PORS] TO [public]
GRANT SELECT ON  [dbo].[PORS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PORS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PORS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PORS] TO [Viewpoint]
GO
