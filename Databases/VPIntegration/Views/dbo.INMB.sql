SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMB] as select a.* From bINMB a

GO
GRANT SELECT ON  [dbo].[INMB] TO [public]
GRANT INSERT ON  [dbo].[INMB] TO [public]
GRANT DELETE ON  [dbo].[INMB] TO [public]
GRANT UPDATE ON  [dbo].[INMB] TO [public]
GO
