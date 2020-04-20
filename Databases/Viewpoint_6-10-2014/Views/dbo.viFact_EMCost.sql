SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viFact_EMCost] AS

/**************************************************
 * ALTERd: TMS 2009-06-15
 * Modified:      
 * Usage:  Fact View returning EM Cost detail from EMCD
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	Company.KeyID		AS EMCoID
,	Department.KeyID	AS DepartmentID
,	Category.KeyID		AS CategoryID
,	Equipment.KeyID		AS EquipmentID
,	CostCode.KeyID		AS CostCodeID
,	CostType.KeyID		AS CostTypeID
,	isnull(Cast(cast(FiscalMonth.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',FiscalMonth.Mth) as varchar(10)) as int),0) as FiscalMthID
,	datediff(dd, '1/1/1950', PostedDate) AS PostedDateID
,	datediff(dd, '1/1/1950', ActualDate) AS ActualDateID
,	Sum(Detail.Dollars) AS Cost
,	Sum(Case When WorkOrderItem.StdMaintGroup is not null then Detail.Dollars else null end) as ScheduledWOCost   
,	Sum(Case When WorkOrderItem.StdMaintGroup is null then Detail.Dollars else null end) as NonScheduledWOCost    
,	Sum(Case When Equipment.FuelCostType=Detail.EMCostType then Detail.Units
			 When Company.FuelCostType=Detail.EMCostType then Detail.Units
		else Null end) as FuelUnits
,	Sum(Detail.Units) as Units
,	Sum(Case when Detail.UM='HRS' and Detail.EMCostType=Company.LaborCT then Detail.Units end) as LaborHours
FROM 	bEMCD Detail With (NoLock)
LEFT JOIN 	bEMCO Company With (NoLock)
	ON  Detail.EMCo = Company.EMCo
LEFT JOIN 	bEMEM Equipment With (NoLock)
	ON  Detail.EMCo			= Equipment.EMCo
	AND Detail.Equipment	= Equipment.Equipment
LEFT JOIN bEMDM Department With (NoLock)
	ON  Detail.EMCo			 = Department.EMCo
	AND Equipment.Department = Department.Department
LEFT JOIN bEMCM Category With (NoLock)
	ON  Detail.EMCo			= Category.EMCo
	AND Equipment.Category	= Category.Category
LEFT JOIN bEMCC CostCode With (NoLock)
	ON  Detail.EMGroup = CostCode.EMGroup
	AND Detail.CostCode = CostCode.CostCode
LEFT JOIN bEMCT CostType With (NoLock)
	ON  Detail.EMGroup = CostType.EMGroup
	AND Detail.EMCostType = CostType.CostType
LEFT JOIN	bEMWI WorkOrderItem With (NoLock)
	ON  Detail.EMCo = WorkOrderItem.EMCo
	AND Detail.WorkOrder=WorkOrderItem.WorkOrder
	AND Detail.WOItem=WorkOrderItem.WOItem
LEFT JOIN	bGLFP FiscalMonth With (NoLock) 
	ON FiscalMonth.GLCo=isnull(Detail.GLCo,Company.GLCo)
	AND FiscalMonth.Mth=Detail.Mth
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Detail.EMCo
GROUP BY 
	Company.KeyID 
,	Department.KeyID 
,	Category.KeyID 
,	Equipment.KeyID 
,	CostCode.KeyID 
,	CostType.KeyID 
,	FiscalMonth.GLCo
,	FiscalMonth.Mth
,	datediff(dd, '1/1/1950', PostedDate) 
,	datediff(dd, '1/1/1950', ActualDate)


GO
GRANT SELECT ON  [dbo].[viFact_EMCost] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMCost] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMCost] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMCost] TO [public]
GRANT SELECT ON  [dbo].[viFact_EMCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_EMCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_EMCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_EMCost] TO [Viewpoint]
GO
