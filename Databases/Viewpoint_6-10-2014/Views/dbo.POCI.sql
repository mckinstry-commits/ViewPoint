SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCI] as select a.* From bPOCI a
GO
GRANT SELECT ON  [dbo].[POCI] TO [public]
GRANT INSERT ON  [dbo].[POCI] TO [public]
GRANT DELETE ON  [dbo].[POCI] TO [public]
GRANT UPDATE ON  [dbo].[POCI] TO [public]
GRANT SELECT ON  [dbo].[POCI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCI] TO [Viewpoint]
GO
