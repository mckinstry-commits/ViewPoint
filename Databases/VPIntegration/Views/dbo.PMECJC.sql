SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[PMECJC] as
	select a.PMCo as [JCCo],
			'PMECUM' = case when a.Basis = 'H' then a.TimeUM else a.UM end,
			a.*
From bPMEC a



GO
GRANT SELECT ON  [dbo].[PMECJC] TO [public]
GRANT INSERT ON  [dbo].[PMECJC] TO [public]
GRANT DELETE ON  [dbo].[PMECJC] TO [public]
GRANT UPDATE ON  [dbo].[PMECJC] TO [public]
GO
