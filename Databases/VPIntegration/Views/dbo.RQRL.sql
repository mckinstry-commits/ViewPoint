SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQRL] as select a.* From bRQRL a

GO
GRANT SELECT ON  [dbo].[RQRL] TO [public]
GRANT INSERT ON  [dbo].[RQRL] TO [public]
GRANT DELETE ON  [dbo].[RQRL] TO [public]
GRANT UPDATE ON  [dbo].[RQRL] TO [public]
GO
