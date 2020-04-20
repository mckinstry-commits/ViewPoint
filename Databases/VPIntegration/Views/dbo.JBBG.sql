SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBBG] as select a.* From bJBBG a

GO
GRANT SELECT ON  [dbo].[JBBG] TO [public]
GRANT INSERT ON  [dbo].[JBBG] TO [public]
GRANT DELETE ON  [dbo].[JBBG] TO [public]
GRANT UPDATE ON  [dbo].[JBBG] TO [public]
GO
