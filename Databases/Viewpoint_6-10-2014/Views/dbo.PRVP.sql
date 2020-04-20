SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRVP] as select a.* from bPRVP a 
GO
GRANT SELECT ON  [dbo].[PRVP] TO [public]
GRANT INSERT ON  [dbo].[PRVP] TO [public]
GRANT DELETE ON  [dbo].[PRVP] TO [public]
GRANT UPDATE ON  [dbo].[PRVP] TO [public]
GRANT SELECT ON  [dbo].[PRVP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRVP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRVP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRVP] TO [Viewpoint]
GO