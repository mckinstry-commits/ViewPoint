SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMIM] as select a.* From bPMIM a
GO
GRANT SELECT ON  [dbo].[PMIM] TO [public]
GRANT INSERT ON  [dbo].[PMIM] TO [public]
GRANT DELETE ON  [dbo].[PMIM] TO [public]
GRANT UPDATE ON  [dbo].[PMIM] TO [public]
GRANT SELECT ON  [dbo].[PMIM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMIM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMIM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMIM] TO [Viewpoint]
GO
