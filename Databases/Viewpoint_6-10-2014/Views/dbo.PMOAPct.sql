SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************
* Created By:	GF 02/20/2008 - issue #127195
*
**************************************/

CREATE view [dbo].[PMOAPct] as 
	select a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, a.AddOn,
			Cast((a.AddOnPercent * 100) as numeric(10,4)) as [PctDisplay]
From PMOA a


GO
GRANT SELECT ON  [dbo].[PMOAPct] TO [public]
GRANT INSERT ON  [dbo].[PMOAPct] TO [public]
GRANT DELETE ON  [dbo].[PMOAPct] TO [public]
GRANT UPDATE ON  [dbo].[PMOAPct] TO [public]
GRANT SELECT ON  [dbo].[PMOAPct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOAPct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOAPct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOAPct] TO [Viewpoint]
GO
