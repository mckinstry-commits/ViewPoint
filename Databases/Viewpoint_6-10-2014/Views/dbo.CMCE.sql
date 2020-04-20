SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMCE] as select a.* From bCMCE a
GO
GRANT SELECT ON  [dbo].[CMCE] TO [public]
GRANT INSERT ON  [dbo].[CMCE] TO [public]
GRANT DELETE ON  [dbo].[CMCE] TO [public]
GRANT UPDATE ON  [dbo].[CMCE] TO [public]
GRANT SELECT ON  [dbo].[CMCE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMCE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMCE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMCE] TO [Viewpoint]
GO
