SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQY] as select a.* From bWDQY a

GO
GRANT SELECT ON  [dbo].[WDQY] TO [public]
GRANT INSERT ON  [dbo].[WDQY] TO [public]
GRANT DELETE ON  [dbo].[WDQY] TO [public]
GRANT UPDATE ON  [dbo].[WDQY] TO [public]
GO
