SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPA] as select a.* From bPMPA a
GO
GRANT SELECT ON  [dbo].[PMPA] TO [public]
GRANT INSERT ON  [dbo].[PMPA] TO [public]
GRANT DELETE ON  [dbo].[PMPA] TO [public]
GRANT UPDATE ON  [dbo].[PMPA] TO [public]
GRANT SELECT ON  [dbo].[PMPA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPA] TO [Viewpoint]
GO
