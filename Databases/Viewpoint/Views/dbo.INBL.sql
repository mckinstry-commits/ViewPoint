SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INBL] as select a.* From bINBL a

GO
GRANT SELECT ON  [dbo].[INBL] TO [public]
GRANT INSERT ON  [dbo].[INBL] TO [public]
GRANT DELETE ON  [dbo].[INBL] TO [public]
GRANT UPDATE ON  [dbo].[INBL] TO [public]
GO
