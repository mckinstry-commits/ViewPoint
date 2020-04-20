SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUR] as select a.* From bPMUR a
GO
GRANT SELECT ON  [dbo].[PMUR] TO [public]
GRANT INSERT ON  [dbo].[PMUR] TO [public]
GRANT DELETE ON  [dbo].[PMUR] TO [public]
GRANT UPDATE ON  [dbo].[PMUR] TO [public]
GRANT SELECT ON  [dbo].[PMUR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMUR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMUR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMUR] TO [Viewpoint]
GO
