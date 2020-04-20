SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCO] as select a.* From bJCCO a

GO
GRANT SELECT ON  [dbo].[JCCO] TO [public]
GRANT INSERT ON  [dbo].[JCCO] TO [public]
GRANT DELETE ON  [dbo].[JCCO] TO [public]
GRANT UPDATE ON  [dbo].[JCCO] TO [public]
GO
