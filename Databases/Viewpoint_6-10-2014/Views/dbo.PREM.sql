SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREM] as select a.* from bPREM a 
GO
GRANT SELECT ON  [dbo].[PREM] TO [public]
GRANT INSERT ON  [dbo].[PREM] TO [public]
GRANT DELETE ON  [dbo].[PREM] TO [public]
GRANT UPDATE ON  [dbo].[PREM] TO [public]
GRANT SELECT ON  [dbo].[PREM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREM] TO [Viewpoint]
GO