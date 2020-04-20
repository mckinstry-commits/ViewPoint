SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE View [dbo].[viDim_HRResource]

/********************************************************
 *   
 * Usage:  Human Resources dimension 
 *         to be used in SSAS Cubes. 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/12/09 129902		C Wirtz		New
 * 11/04/10 135047		H Huynh		Join bHRCO for company security
 *
 ********************************************************/

AS



Select  bHRCO.KeyID as HRCoID
		,bHRRM.KeyID as HRRefID
		,bHRRM.HRRef
		,bHRRM.LastName As HRLastName
		,bHRRM.FirstName AS HRFirstName
		,bHRRM.MiddleName AS HRMiddleName
		,cast(bHRRM.HRRef as varchar) + ' ' + bHRRM.LastName as HRRefandLastName
		,bPREH.KeyID as PREmpID
		,Case bHRRM.Sex 
			When 'M' Then 'Male'
			When 'F' Then 'Female'
			Else 'Unassigned'
		 End as Gender
		,bPRRC.KeyID as RaceID 
		,bPRRC.Description as Race
		,bPRRC.EEOCat as EEOCatagory
		,bHRST.KeyID as EmploymentStatusID
		,bHRST.Description as EmploymentStatus
		,bHRRM.HireDate 
		,datediff(dd,'1/1/1950',bHRRM.HireDate) as HiredDateID
		,bHRRM.TermDate 
		,datediff(dd,'1/1/1950',bHRRM.TermDate) as TerminationDateID
		,bPROP.KeyID as OccupationCategoryID
		,bPROP.Description as OccupationCategory
		,EmployedResource = Case When bHRRM.HireDate is null then 'N' else 'Y' End
From bHRRM  With (NoLock)
Inner Join vDDBICompanies on vDDBICompanies.Co=bHRRM.HRCo
Inner Join bHRCO With (NoLock) on bHRCO.HRCo = bHRRM.HRCo
left outer Join bPREH With (NoLock)
	ON 	bHRRM.PRCo = bPREH.PRCo and bHRRM.PREmp = bPREH.Employee
Left Outer Join bPRRC With (NoLock)
	ON bHRRM.PRCo = bPRRC.PRCo and bHRRM.Race = bPRRC.Race
Left Outer Join bHRST With (NoLock)
	ON bHRRM.HRCo = bHRST.HRCo and bHRRM.Status = bHRST.StatusCode
Left Outer Join bPROP With (NoLock)
	ON bHRRM.PRCo = bPROP.PRCo and bHRRM.OccupCat = bPROP.OccupCat

Union All
Select  null
		,0 as HRRefID
		,null             --HRRef Field for testing purposes only
		,'UnassignedLastName' AS HRLastName
		,'UnassignedFirstName' AS HRFirstName
		,'UnassignedMiddleName' AS HRMiddleName
		,null
		,0 as PREmpID
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null


GO
GRANT SELECT ON  [dbo].[viDim_HRResource] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRResource] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRResource] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRResource] TO [public]
GO
