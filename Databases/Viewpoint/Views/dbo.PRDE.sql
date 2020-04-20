SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDE] as select a.* From bPRDE a

GO
GRANT SELECT ON  [dbo].[PRDE] TO [public]
GRANT INSERT ON  [dbo].[PRDE] TO [public]
GRANT DELETE ON  [dbo].[PRDE] TO [public]
GRANT UPDATE ON  [dbo].[PRDE] TO [public]
GO
