SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRID] as select a.* From bPRID a

GO
GRANT SELECT ON  [dbo].[PRID] TO [public]
GRANT INSERT ON  [dbo].[PRID] TO [public]
GRANT DELETE ON  [dbo].[PRID] TO [public]
GRANT UPDATE ON  [dbo].[PRID] TO [public]
GO
