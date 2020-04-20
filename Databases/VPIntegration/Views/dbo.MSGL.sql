SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSGL] as select a.* From bMSGL a

GO
GRANT SELECT ON  [dbo].[MSGL] TO [public]
GRANT INSERT ON  [dbo].[MSGL] TO [public]
GRANT DELETE ON  [dbo].[MSGL] TO [public]
GRANT UPDATE ON  [dbo].[MSGL] TO [public]
GO
