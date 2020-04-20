SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRPS] as select a.* From bPRPS a

GO
GRANT SELECT ON  [dbo].[PRPS] TO [public]
GRANT INSERT ON  [dbo].[PRPS] TO [public]
GRANT DELETE ON  [dbo].[PRPS] TO [public]
GRANT UPDATE ON  [dbo].[PRPS] TO [public]
GO
