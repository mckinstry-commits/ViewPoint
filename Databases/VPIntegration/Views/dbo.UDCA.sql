SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDCA] as select a.* From bUDCA a

GO
GRANT SELECT ON  [dbo].[UDCA] TO [public]
GRANT INSERT ON  [dbo].[UDCA] TO [public]
GRANT DELETE ON  [dbo].[UDCA] TO [public]
GRANT UPDATE ON  [dbo].[UDCA] TO [public]
GO
