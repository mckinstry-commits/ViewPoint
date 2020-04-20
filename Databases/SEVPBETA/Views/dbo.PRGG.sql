SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGG] as select a.* From bPRGG a

GO
GRANT SELECT ON  [dbo].[PRGG] TO [public]
GRANT INSERT ON  [dbo].[PRGG] TO [public]
GRANT DELETE ON  [dbo].[PRGG] TO [public]
GRANT UPDATE ON  [dbo].[PRGG] TO [public]
GO
