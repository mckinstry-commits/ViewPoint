SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMDA] as select a.* From bCMDA a
GO
GRANT SELECT ON  [dbo].[CMDA] TO [public]
GRANT INSERT ON  [dbo].[CMDA] TO [public]
GRANT DELETE ON  [dbo].[CMDA] TO [public]
GRANT UPDATE ON  [dbo].[CMDA] TO [public]
GRANT SELECT ON  [dbo].[CMDA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMDA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMDA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMDA] TO [Viewpoint]
GO
