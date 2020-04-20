SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTL] as select a.* from bPRTL a 
GO
GRANT SELECT ON  [dbo].[PRTL] TO [public]
GRANT INSERT ON  [dbo].[PRTL] TO [public]
GRANT DELETE ON  [dbo].[PRTL] TO [public]
GRANT UPDATE ON  [dbo].[PRTL] TO [public]
GRANT SELECT ON  [dbo].[PRTL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTL] TO [Viewpoint]
GO