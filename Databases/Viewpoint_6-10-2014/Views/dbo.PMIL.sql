SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMIL] as select a.* From bPMIL a
GO
GRANT SELECT ON  [dbo].[PMIL] TO [public]
GRANT INSERT ON  [dbo].[PMIL] TO [public]
GRANT DELETE ON  [dbo].[PMIL] TO [public]
GRANT UPDATE ON  [dbo].[PMIL] TO [public]
GRANT SELECT ON  [dbo].[PMIL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMIL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMIL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMIL] TO [Viewpoint]
GO
