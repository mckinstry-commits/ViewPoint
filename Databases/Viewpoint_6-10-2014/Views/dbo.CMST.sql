SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMST] as select a.* From bCMST a
GO
GRANT SELECT ON  [dbo].[CMST] TO [public]
GRANT INSERT ON  [dbo].[CMST] TO [public]
GRANT DELETE ON  [dbo].[CMST] TO [public]
GRANT UPDATE ON  [dbo].[CMST] TO [public]
GRANT SELECT ON  [dbo].[CMST] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMST] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMST] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMST] TO [Viewpoint]
GO
