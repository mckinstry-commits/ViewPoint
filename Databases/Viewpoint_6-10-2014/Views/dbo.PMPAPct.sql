SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************
* Created By:	GF 02/20/2008 - issue #127195
*
**************************************/

CREATE view [dbo].[PMPAPct] as 
	select a.PMCo, a.Project, a.AddOn, Cast((a.Pct * 100) as numeric(10,4)) as [PctDisplay]
From PMPA a


GO
GRANT SELECT ON  [dbo].[PMPAPct] TO [public]
GRANT INSERT ON  [dbo].[PMPAPct] TO [public]
GRANT DELETE ON  [dbo].[PMPAPct] TO [public]
GRANT UPDATE ON  [dbo].[PMPAPct] TO [public]
GRANT SELECT ON  [dbo].[PMPAPct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPAPct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPAPct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPAPct] TO [Viewpoint]
GO
