SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBLR] as select a.* From bJBLR a

GO
GRANT SELECT ON  [dbo].[JBLR] TO [public]
GRANT INSERT ON  [dbo].[JBLR] TO [public]
GRANT DELETE ON  [dbo].[JBLR] TO [public]
GRANT UPDATE ON  [dbo].[JBLR] TO [public]
GO
