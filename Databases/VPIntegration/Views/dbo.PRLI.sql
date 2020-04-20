SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRLI] as select a.* From bPRLI a

GO
GRANT SELECT ON  [dbo].[PRLI] TO [public]
GRANT INSERT ON  [dbo].[PRLI] TO [public]
GRANT DELETE ON  [dbo].[PRLI] TO [public]
GRANT UPDATE ON  [dbo].[PRLI] TO [public]
GO
