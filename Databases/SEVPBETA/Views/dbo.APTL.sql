SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APTL] as select a.* From bAPTL a
GO
GRANT SELECT ON  [dbo].[APTL] TO [public]
GRANT INSERT ON  [dbo].[APTL] TO [public]
GRANT DELETE ON  [dbo].[APTL] TO [public]
GRANT UPDATE ON  [dbo].[APTL] TO [public]
GO
