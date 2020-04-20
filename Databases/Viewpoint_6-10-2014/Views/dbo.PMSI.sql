SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMSI] as select a.* From bPMSI a
GO
GRANT SELECT ON  [dbo].[PMSI] TO [public]
GRANT INSERT ON  [dbo].[PMSI] TO [public]
GRANT DELETE ON  [dbo].[PMSI] TO [public]
GRANT UPDATE ON  [dbo].[PMSI] TO [public]
GRANT SELECT ON  [dbo].[PMSI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSI] TO [Viewpoint]
GO
