SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPH] as select a.* From bAPPH a
GO
GRANT SELECT ON  [dbo].[APPH] TO [public]
GRANT INSERT ON  [dbo].[APPH] TO [public]
GRANT DELETE ON  [dbo].[APPH] TO [public]
GRANT UPDATE ON  [dbo].[APPH] TO [public]
GO
