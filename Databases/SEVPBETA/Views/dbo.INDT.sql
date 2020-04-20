SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INDT] as select a.* From bINDT a
GO
GRANT SELECT ON  [dbo].[INDT] TO [public]
GRANT INSERT ON  [dbo].[INDT] TO [public]
GRANT DELETE ON  [dbo].[INDT] TO [public]
GRANT UPDATE ON  [dbo].[INDT] TO [public]
GO
