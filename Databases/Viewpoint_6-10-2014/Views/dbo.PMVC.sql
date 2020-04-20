SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMVC] as select a.* From bPMVC a

GO
GRANT SELECT ON  [dbo].[PMVC] TO [public]
GRANT INSERT ON  [dbo].[PMVC] TO [public]
GRANT DELETE ON  [dbo].[PMVC] TO [public]
GRANT UPDATE ON  [dbo].[PMVC] TO [public]
GRANT SELECT ON  [dbo].[PMVC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMVC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMVC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMVC] TO [Viewpoint]
GO
