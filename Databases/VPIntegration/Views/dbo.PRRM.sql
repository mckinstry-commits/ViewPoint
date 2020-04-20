SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRM] as select a.* From bPRRM a

GO
GRANT SELECT ON  [dbo].[PRRM] TO [public]
GRANT INSERT ON  [dbo].[PRRM] TO [public]
GRANT DELETE ON  [dbo].[PRRM] TO [public]
GRANT UPDATE ON  [dbo].[PRRM] TO [public]
GO
