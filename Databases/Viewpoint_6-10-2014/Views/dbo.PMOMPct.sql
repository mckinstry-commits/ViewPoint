SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**************************************
* Created By:	GF 05/19/2009 - issue #133627
*
**************************************/

CREATE view [dbo].[PMOMPct] as 
	select a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.PhaseGroup, a.CostType,
			Cast((a.IntMarkUp * 100) as numeric(10,4)) as [IntMarkUpDisplay],
			Cast((a.ConMarkUp * 100) as numeric(10,4)) as [ConMarkUpDisplay]
From PMOM a



GO
GRANT SELECT ON  [dbo].[PMOMPct] TO [public]
GRANT INSERT ON  [dbo].[PMOMPct] TO [public]
GRANT DELETE ON  [dbo].[PMOMPct] TO [public]
GRANT UPDATE ON  [dbo].[PMOMPct] TO [public]
GRANT SELECT ON  [dbo].[PMOMPct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOMPct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOMPct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOMPct] TO [Viewpoint]
GO
