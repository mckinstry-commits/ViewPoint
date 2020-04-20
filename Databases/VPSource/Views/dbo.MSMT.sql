SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMT] as select a.* From bMSMT a

GO
GRANT SELECT ON  [dbo].[MSMT] TO [public]
GRANT INSERT ON  [dbo].[MSMT] TO [public]
GRANT DELETE ON  [dbo].[MSMT] TO [public]
GRANT UPDATE ON  [dbo].[MSMT] TO [public]
GO
