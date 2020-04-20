SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMDT] as select a.* From bCMDT a
GO
GRANT SELECT ON  [dbo].[CMDT] TO [public]
GRANT INSERT ON  [dbo].[CMDT] TO [public]
GRANT DELETE ON  [dbo].[CMDT] TO [public]
GRANT UPDATE ON  [dbo].[CMDT] TO [public]
GRANT SELECT ON  [dbo].[CMDT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMDT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMDT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMDT] TO [Viewpoint]
GO
