SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRW2MiscDetail] as select a.* From bPRW2MiscDetail a
GO
GRANT SELECT ON  [dbo].[PRW2MiscDetail] TO [public]
GRANT INSERT ON  [dbo].[PRW2MiscDetail] TO [public]
GRANT DELETE ON  [dbo].[PRW2MiscDetail] TO [public]
GRANT UPDATE ON  [dbo].[PRW2MiscDetail] TO [public]
GO
