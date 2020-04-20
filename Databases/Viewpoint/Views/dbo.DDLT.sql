SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDLT] as select * from vDDLT

GO
GRANT SELECT ON  [dbo].[DDLT] TO [public]
GRANT INSERT ON  [dbo].[DDLT] TO [public]
GRANT DELETE ON  [dbo].[DDLT] TO [public]
GRANT UPDATE ON  [dbo].[DDLT] TO [public]
GO
