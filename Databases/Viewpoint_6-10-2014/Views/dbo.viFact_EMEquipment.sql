SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viFact_EMEquipment] AS

/**************************************************
 * ALTERd: TMS 2009-06-15
 * Modified:      
 * Usage:  Fact View returning EM  
 *		   data from EMEM for use in SSAS Cubes. 
 *
 **************************************************/


SELECT 
	Company.KeyID		AS EMCoID
,	Department.KeyID	AS DepartmentID
,	Category.KeyID		AS CategoryID
,	Detail.KeyID		AS EquipmentID
,	ReplCost			AS ReplacementCost
,	CurrentAppraisal	AS CurrentAppraisal
,   datediff(dd, '1/1/1950', LicensePlateExpDate) as 'LicensePlateExpDateID'
,   datediff(dd, Getdate(), LicensePlateExpDate) as 'DaysLeft'
FROM 	bEMEM Detail With (NoLock)
LEFT OUTER JOIN 	bEMCO Company With (NoLock)
		ON  Detail.EMCo = Company.EMCo
LEFT OUTER JOIN 	bEMDM Department With (NoLock)
		ON  Detail.EMCo			 = Department.EMCo
		AND Detail.Department = Department.Department
LEFT OUTER JOIN  bEMCM Category With (NoLock)
		ON  Detail.EMCo			= Category.EMCo
		AND Detail.Category	= Category.Category
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Detail.EMCo


GO
GRANT SELECT ON  [dbo].[viFact_EMEquipment] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMEquipment] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMEquipment] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMEquipment] TO [public]
GRANT SELECT ON  [dbo].[viFact_EMEquipment] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_EMEquipment] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_EMEquipment] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_EMEquipment] TO [Viewpoint]
GO
