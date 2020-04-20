SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQP] as select a.* From bWDQP a

GO
GRANT SELECT ON  [dbo].[WDQP] TO [public]
GRANT INSERT ON  [dbo].[WDQP] TO [public]
GRANT DELETE ON  [dbo].[WDQP] TO [public]
GRANT UPDATE ON  [dbo].[WDQP] TO [public]
GO
