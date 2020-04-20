SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTF] as select a.* From bPRTF a
GO
GRANT SELECT ON  [dbo].[PRTF] TO [public]
GRANT INSERT ON  [dbo].[PRTF] TO [public]
GRANT DELETE ON  [dbo].[PRTF] TO [public]
GRANT UPDATE ON  [dbo].[PRTF] TO [public]
GRANT SELECT ON  [dbo].[PRTF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTF] TO [Viewpoint]
GO
