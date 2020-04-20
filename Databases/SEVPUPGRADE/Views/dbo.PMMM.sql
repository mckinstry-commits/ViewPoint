SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMMM] as select a.* From bPMMM a
GO
GRANT SELECT ON  [dbo].[PMMM] TO [public]
GRANT INSERT ON  [dbo].[PMMM] TO [public]
GRANT DELETE ON  [dbo].[PMMM] TO [public]
GRANT UPDATE ON  [dbo].[PMMM] TO [public]
GO
