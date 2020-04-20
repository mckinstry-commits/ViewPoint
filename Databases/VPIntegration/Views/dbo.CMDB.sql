SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMDB] as select a.* From bCMDB a
GO
GRANT SELECT ON  [dbo].[CMDB] TO [public]
GRANT INSERT ON  [dbo].[CMDB] TO [public]
GRANT DELETE ON  [dbo].[CMDB] TO [public]
GRANT UPDATE ON  [dbo].[CMDB] TO [public]
GO
