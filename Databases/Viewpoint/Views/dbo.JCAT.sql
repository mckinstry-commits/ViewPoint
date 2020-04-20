SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCAT] as select a.* From bJCAT a

GO
GRANT SELECT ON  [dbo].[JCAT] TO [public]
GRANT INSERT ON  [dbo].[JCAT] TO [public]
GRANT DELETE ON  [dbo].[JCAT] TO [public]
GRANT UPDATE ON  [dbo].[JCAT] TO [public]
GO
