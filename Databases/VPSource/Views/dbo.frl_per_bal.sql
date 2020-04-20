SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_per_bal] as select a.* From vfrl_per_bal a

GO
GRANT SELECT ON  [dbo].[frl_per_bal] TO [public]
GRANT INSERT ON  [dbo].[frl_per_bal] TO [public]
GRANT DELETE ON  [dbo].[frl_per_bal] TO [public]
GRANT UPDATE ON  [dbo].[frl_per_bal] TO [public]
GO
