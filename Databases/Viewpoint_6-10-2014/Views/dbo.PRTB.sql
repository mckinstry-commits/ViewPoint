SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTB] as select a.* From bPRTB a
GO
GRANT SELECT ON  [dbo].[PRTB] TO [public]
GRANT INSERT ON  [dbo].[PRTB] TO [public]
GRANT DELETE ON  [dbo].[PRTB] TO [public]
GRANT UPDATE ON  [dbo].[PRTB] TO [public]
GRANT SELECT ON  [dbo].[PRTB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTB] TO [Viewpoint]
GO
