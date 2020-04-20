SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************
* Created By:	GF 02/20/2008 - issue #127195
*
**************************************/


CREATE view [dbo].[PMCAPct] as 
	select a.PMCo, a.Addon, Cast((a.Pct * 100) as numeric(10,4)) as [PctDisplay]
From PMCA a


GO
GRANT SELECT ON  [dbo].[PMCAPct] TO [public]
GRANT INSERT ON  [dbo].[PMCAPct] TO [public]
GRANT DELETE ON  [dbo].[PMCAPct] TO [public]
GRANT UPDATE ON  [dbo].[PMCAPct] TO [public]
GRANT SELECT ON  [dbo].[PMCAPct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCAPct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCAPct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCAPct] TO [Viewpoint]
GO
