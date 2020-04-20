SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCP] as select a.* From bPRCP a
GO
GRANT SELECT ON  [dbo].[PRCP] TO [public]
GRANT INSERT ON  [dbo].[PRCP] TO [public]
GRANT DELETE ON  [dbo].[PRCP] TO [public]
GRANT UPDATE ON  [dbo].[PRCP] TO [public]
GO
