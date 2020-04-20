SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INXB] as select a.* From bINXB a

GO
GRANT SELECT ON  [dbo].[INXB] TO [public]
GRANT INSERT ON  [dbo].[INXB] TO [public]
GRANT DELETE ON  [dbo].[INXB] TO [public]
GRANT UPDATE ON  [dbo].[INXB] TO [public]
GO
