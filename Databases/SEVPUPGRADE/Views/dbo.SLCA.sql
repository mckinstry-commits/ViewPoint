SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLCA] as select a.* From bSLCA a

GO
GRANT SELECT ON  [dbo].[SLCA] TO [public]
GRANT INSERT ON  [dbo].[SLCA] TO [public]
GRANT DELETE ON  [dbo].[SLCA] TO [public]
GRANT UPDATE ON  [dbo].[SLCA] TO [public]
GO
