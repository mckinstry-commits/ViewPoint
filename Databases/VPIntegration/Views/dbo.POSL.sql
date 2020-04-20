SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POSL] as select a.* From bPOSL a

GO
GRANT SELECT ON  [dbo].[POSL] TO [public]
GRANT INSERT ON  [dbo].[POSL] TO [public]
GRANT DELETE ON  [dbo].[POSL] TO [public]
GRANT UPDATE ON  [dbo].[POSL] TO [public]
GO
