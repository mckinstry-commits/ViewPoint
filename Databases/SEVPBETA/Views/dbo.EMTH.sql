SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTH] as select a.* From bEMTH a
GO
GRANT SELECT ON  [dbo].[EMTH] TO [public]
GRANT INSERT ON  [dbo].[EMTH] TO [public]
GRANT DELETE ON  [dbo].[EMTH] TO [public]
GRANT UPDATE ON  [dbo].[EMTH] TO [public]
GO
