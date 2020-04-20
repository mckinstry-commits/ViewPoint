SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCM] as select a.* From bPRCM a
GO
GRANT SELECT ON  [dbo].[PRCM] TO [public]
GRANT INSERT ON  [dbo].[PRCM] TO [public]
GRANT DELETE ON  [dbo].[PRCM] TO [public]
GRANT UPDATE ON  [dbo].[PRCM] TO [public]
GRANT SELECT ON  [dbo].[PRCM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCM] TO [Viewpoint]
GO
