SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMHA] as select a.* From bPMHA a
GO
GRANT SELECT ON  [dbo].[PMHA] TO [public]
GRANT INSERT ON  [dbo].[PMHA] TO [public]
GRANT DELETE ON  [dbo].[PMHA] TO [public]
GRANT UPDATE ON  [dbo].[PMHA] TO [public]
GRANT SELECT ON  [dbo].[PMHA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMHA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMHA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMHA] TO [Viewpoint]
GO
