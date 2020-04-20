SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUI] as select a.* From bPMUI a

GO
GRANT SELECT ON  [dbo].[PMUI] TO [public]
GRANT INSERT ON  [dbo].[PMUI] TO [public]
GRANT DELETE ON  [dbo].[PMUI] TO [public]
GRANT UPDATE ON  [dbo].[PMUI] TO [public]
GRANT SELECT ON  [dbo].[PMUI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMUI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMUI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMUI] TO [Viewpoint]
GO
