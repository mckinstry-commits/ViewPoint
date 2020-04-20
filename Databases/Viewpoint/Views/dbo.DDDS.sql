SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDDS] as select * from vDDDS

GO
GRANT SELECT ON  [dbo].[DDDS] TO [public]
GRANT INSERT ON  [dbo].[DDDS] TO [public]
GRANT DELETE ON  [dbo].[DDDS] TO [public]
GRANT UPDATE ON  [dbo].[DDDS] TO [public]
GO
