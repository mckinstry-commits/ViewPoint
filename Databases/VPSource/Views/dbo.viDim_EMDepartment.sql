SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMDepartment] AS

/**************************************************
 * ALTERED:		TMS 2009-06-03
 * Modified:	HH 2010-11-04	#135047	Join bEMCO for company security
 * Usage:  Dimension View from Department Master 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	Deptartment.KeyID AS DepartmentID
,	bEMCO.KeyID AS EMCoID	
,	Department
,	Description as DepartmentName
,	isnull(Department, '') + '  ' + isnull(Description, '') AS DepartmentAndDescription

FROM
	bEMDM AS Deptartment
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = Deptartment.EMCo 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Deptartment.EMCo 


UNION ALL 

-- Unassigned record
SELECT 
	 0		,null		,null		,'Unassigned'
	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMDepartment] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMDepartment] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMDepartment] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMDepartment] TO [public]
GO
