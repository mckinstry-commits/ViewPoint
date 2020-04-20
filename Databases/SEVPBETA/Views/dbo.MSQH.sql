SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[MSQH] as select a.* From bMSQH a



GO
GRANT SELECT ON  [dbo].[MSQH] TO [public]
GRANT INSERT ON  [dbo].[MSQH] TO [public]
GRANT DELETE ON  [dbo].[MSQH] TO [public]
GRANT UPDATE ON  [dbo].[MSQH] TO [public]
GO
