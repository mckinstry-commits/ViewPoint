SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCM] as select a.* From bHRCM a
GO
GRANT SELECT ON  [dbo].[HRCM] TO [public]
GRANT INSERT ON  [dbo].[HRCM] TO [public]
GRANT DELETE ON  [dbo].[HRCM] TO [public]
GRANT UPDATE ON  [dbo].[HRCM] TO [public]
GRANT SELECT ON  [dbo].[HRCM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRCM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRCM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRCM] TO [Viewpoint]
GO
