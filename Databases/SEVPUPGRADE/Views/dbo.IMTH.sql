SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMTH] as select a.* From bIMTH a

GO
GRANT SELECT ON  [dbo].[IMTH] TO [public]
GRANT INSERT ON  [dbo].[IMTH] TO [public]
GRANT DELETE ON  [dbo].[IMTH] TO [public]
GRANT UPDATE ON  [dbo].[IMTH] TO [public]
GO
