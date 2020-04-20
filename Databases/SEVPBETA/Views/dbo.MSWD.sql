SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSWD] as select a.* From bMSWD a

GO
GRANT SELECT ON  [dbo].[MSWD] TO [public]
GRANT INSERT ON  [dbo].[MSWD] TO [public]
GRANT DELETE ON  [dbo].[MSWD] TO [public]
GRANT UPDATE ON  [dbo].[MSWD] TO [public]
GO
