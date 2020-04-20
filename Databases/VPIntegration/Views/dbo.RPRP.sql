SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRP] as select a.* From vRPRP a
GO
GRANT SELECT ON  [dbo].[RPRP] TO [public]
GRANT INSERT ON  [dbo].[RPRP] TO [public]
GRANT DELETE ON  [dbo].[RPRP] TO [public]
GRANT UPDATE ON  [dbo].[RPRP] TO [public]
GO
