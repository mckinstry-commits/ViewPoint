SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRB] as select a.* From bPRRB a
GO
GRANT SELECT ON  [dbo].[PRRB] TO [public]
GRANT INSERT ON  [dbo].[PRRB] TO [public]
GRANT DELETE ON  [dbo].[PRRB] TO [public]
GRANT UPDATE ON  [dbo].[PRRB] TO [public]
GO
