SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSQ] as select a.* from bPRSQ a 
GO
GRANT SELECT ON  [dbo].[PRSQ] TO [public]
GRANT INSERT ON  [dbo].[PRSQ] TO [public]
GRANT DELETE ON  [dbo].[PRSQ] TO [public]
GRANT UPDATE ON  [dbo].[PRSQ] TO [public]
GRANT SELECT ON  [dbo].[PRSQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRSQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRSQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRSQ] TO [Viewpoint]
GO