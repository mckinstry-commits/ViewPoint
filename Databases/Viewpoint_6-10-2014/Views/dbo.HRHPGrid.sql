SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.HRHPGrid
AS
SELECT     r.HRCo, r.PRCo, r.Employee, r.HRRef, CASE r.UpdateOpt WHEN 'H' THEN h.LastName + ', ' + h.FirstName + ' ' + isnull(h.MiddleName, '') 
                      WHEN 'P' THEN p.LastName + ', ' + p.FirstName + ' ' + isnull(p.MidName, '') END AS 'Name', r.Status, r.ErrMsg
FROM         dbo.bHRHP AS r WITH (nolock) LEFT OUTER JOIN
                      dbo.bHRRM AS h WITH (nolock) ON r.HRCo = h.HRCo AND r.HRRef = h.HRRef LEFT OUTER JOIN
                      dbo.bPREH AS p WITH (nolock) ON r.PRCo = p.PRCo AND r.Employee = p.Employee


GO
GRANT SELECT ON  [dbo].[HRHPGrid] TO [public]
GRANT INSERT ON  [dbo].[HRHPGrid] TO [public]
GRANT DELETE ON  [dbo].[HRHPGrid] TO [public]
GRANT UPDATE ON  [dbo].[HRHPGrid] TO [public]
GRANT SELECT ON  [dbo].[HRHPGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRHPGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRHPGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRHPGrid] TO [Viewpoint]
GO
