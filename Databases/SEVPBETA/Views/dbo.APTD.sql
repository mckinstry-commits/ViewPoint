SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APTD] as select a.* From bAPTD a
GO
GRANT SELECT ON  [dbo].[APTD] TO [public]
GRANT INSERT ON  [dbo].[APTD] TO [public]
GRANT DELETE ON  [dbo].[APTD] TO [public]
GRANT UPDATE ON  [dbo].[APTD] TO [public]
GO
