SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQTC] as select a.* From bHQTC a

GO
GRANT SELECT ON  [dbo].[HQTC] TO [public]
GRANT INSERT ON  [dbo].[HQTC] TO [public]
GRANT DELETE ON  [dbo].[HQTC] TO [public]
GRANT UPDATE ON  [dbo].[HQTC] TO [public]
GO
