SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBJC] as select a.* From bJBJC a

GO
GRANT SELECT ON  [dbo].[JBJC] TO [public]
GRANT INSERT ON  [dbo].[JBJC] TO [public]
GRANT DELETE ON  [dbo].[JBJC] TO [public]
GRANT UPDATE ON  [dbo].[JBJC] TO [public]
GO
