SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTM] as select a.* From bPRTM a
GO
GRANT SELECT ON  [dbo].[PRTM] TO [public]
GRANT INSERT ON  [dbo].[PRTM] TO [public]
GRANT DELETE ON  [dbo].[PRTM] TO [public]
GRANT UPDATE ON  [dbo].[PRTM] TO [public]
GRANT SELECT ON  [dbo].[PRTM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTM] TO [Viewpoint]
GO
