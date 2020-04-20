SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[INMT] as select a.* From bINMT a

GO
GRANT SELECT ON  [dbo].[INMT] TO [public]
GRANT INSERT ON  [dbo].[INMT] TO [public]
GRANT DELETE ON  [dbo].[INMT] TO [public]
GRANT UPDATE ON  [dbo].[INMT] TO [public]
GO
