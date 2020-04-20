SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMCD] as select a.* From bPMCD a
GO
GRANT SELECT ON  [dbo].[PMCD] TO [public]
GRANT INSERT ON  [dbo].[PMCD] TO [public]
GRANT DELETE ON  [dbo].[PMCD] TO [public]
GRANT UPDATE ON  [dbo].[PMCD] TO [public]
GRANT SELECT ON  [dbo].[PMCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCD] TO [Viewpoint]
GO
