SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POJC] as select a.* From bPOJC a

GO
GRANT SELECT ON  [dbo].[POJC] TO [public]
GRANT INSERT ON  [dbo].[POJC] TO [public]
GRANT DELETE ON  [dbo].[POJC] TO [public]
GRANT UPDATE ON  [dbo].[POJC] TO [public]
GO
