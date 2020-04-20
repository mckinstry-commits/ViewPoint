SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APUL] as select a.* From bAPUL a
GO
GRANT SELECT ON  [dbo].[APUL] TO [public]
GRANT INSERT ON  [dbo].[APUL] TO [public]
GRANT DELETE ON  [dbo].[APUL] TO [public]
GRANT UPDATE ON  [dbo].[APUL] TO [public]
GO
