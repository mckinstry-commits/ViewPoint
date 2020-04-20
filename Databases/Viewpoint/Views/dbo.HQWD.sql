SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[HQWD] as select a.* From bHQWD a


GO
GRANT SELECT ON  [dbo].[HQWD] TO [public]
GRANT INSERT ON  [dbo].[HQWD] TO [public]
GRANT DELETE ON  [dbo].[HQWD] TO [public]
GRANT UPDATE ON  [dbo].[HQWD] TO [public]
GO
