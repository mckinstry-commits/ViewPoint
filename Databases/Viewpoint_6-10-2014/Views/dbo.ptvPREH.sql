SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPREH]
AS

-- PR Employees
-- Returns Craft and Class info if it is set up for the employee

SELECT PREH.Employee, PREH.LastName+', '+isnull(PREH.FirstName,'')+' '+isnull(PREH.MidName,'') AS Name, PREH.Craft, 	
	PRCM.Description AS CraftDesc, PREH.Class, PRCC.Description AS ClassDesc, PREH.EarnCode, PREH.PRCo 

FROM (PREH with (nolock)
	left JOIN PRCM with (nolock)ON (PREH.Craft=PRCM.Craft) AND (PREH.PRCo=PRCM.PRCo)) 
	Left JOIN PRCC with (nolock)ON (PREH.PRCo=PRCC.PRCo) AND (PREH.Craft=PRCC.Craft) AND (PREH.Class=PRCC.Class)

WHERE PREH.ActiveYN='Y'

GO
GRANT SELECT ON  [dbo].[ptvPREH] TO [public]
GRANT INSERT ON  [dbo].[ptvPREH] TO [public]
GRANT DELETE ON  [dbo].[ptvPREH] TO [public]
GRANT UPDATE ON  [dbo].[ptvPREH] TO [public]
GRANT SELECT ON  [dbo].[ptvPREH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPREH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPREH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPREH] TO [Viewpoint]
GO
