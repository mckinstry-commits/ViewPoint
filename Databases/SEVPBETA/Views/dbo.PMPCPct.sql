SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/**************************************
* Created By:	GF 05/19/2009 - issue #133627
*
**************************************/


CREATE view [dbo].[PMPCPct] as 
	select a.PMCo, a.Project, a.PhaseGroup, a.CostType, Cast((a.Markup * 100) as numeric(10,4)) as [MarkupDisplay]
From PMPC a




GO
GRANT SELECT ON  [dbo].[PMPCPct] TO [public]
GRANT INSERT ON  [dbo].[PMPCPct] TO [public]
GRANT DELETE ON  [dbo].[PMPCPct] TO [public]
GRANT UPDATE ON  [dbo].[PMPCPct] TO [public]
GO
