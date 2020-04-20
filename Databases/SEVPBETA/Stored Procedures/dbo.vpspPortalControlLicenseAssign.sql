SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Chris G
-- Create date: 2/11/2010
-- Description:	
--		Procedure to retrieve Portal Control License Assignments.  Returns a pivot table of the
--		license types as set of columns after Name.  This is mainly used by the stand alone in-house
--		app that allows VP staff to view and update license assignments.
-- Inputs:
--	@filterControlID   	Filter by Portal Control ID
--	@filterControlName	Fitler by Name
-- =============================================
CREATE PROCEDURE [dbo].[vpspPortalControlLicenseAssign] 
	(@filterControlID int = null, @filterControlName varchar(50) = null)
AS
BEGIN

select PortalControlID,
	   Name,
	   -----------------------------------------------------------------
	   -- License Type columns.  Format as 'LTID[X]' where X is the license
	   -- type ID from pLicenseType.  The code replaces the name with
	   -- the abbreviated description by matching X to the ID in the
	   -- pLicenseType table to make them somewhat dynamic.
	   [1] AS 'LTID1',
	   [2] AS 'LTID2',
	   [3] AS 'LTID3',
	   -----------------------------------------------------------------
	   [Description],
	   [Path],
	   Notes,
	   PrimaryTable
From
	(
	select pPortalControls.*, pPortalControlLicenseType.LicenseTypeID  from pPortalControls
		left join pPortalControlLicenseType ON pPortalControlLicenseType.PortalControlID = pPortalControls.PortalControlID
	where
		pPortalControls.PortalControlID = ISNULL(@filterControlID, pPortalControls.PortalControlID)
		AND
		(@filterControlName IS NULL OR
			pPortalControls.Name Like '%' + @filterControlName + '%')
	) AS PortalLicenseTypes
PIVOT
	(
	COUNT(PortalLicenseTypes.LicenseTypeID) -- This returns 0 is not assigned or 1 if assigned
	FOR PortalLicenseTypes.LicenseTypeID IN ([1],[2],[3]) -- LicenseTypeIDs
	) AS PivotTable
ORDER BY
	Name;
	
END



GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlLicenseAssign] TO [VCSPortal]
GO
