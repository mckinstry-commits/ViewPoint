SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viFact_EMWorkOrder] AS

/**************************************************
 * ALTERd: TMS 2009-06-15
 * Modified:PMB 2009-7-20      
 * Usage:  Fact View returning a list of Work Order
 *		   items for use in SSAS Cubes. 
 *
 **************************************************/


SELECT 
Company.KeyID	as 'EMCoID',
Department.KeyID as 'DepartmentID',
Category.KeyID	as 'CategoryID',
Equipment.KeyID		as 'EquipmentID',
WorkOrders.KeyID	as 'WorkOrderID',
Detail.KeyID		as 'WorkOrderItemID',
Employee.KeyID		as 'MechanicID',
EMCC.KeyID as 'CostCodeID',
datediff(dd, '1/1/1950', Detail.DateCreated)	as 'DateCreatedID',
datediff(dd, '1/1/1950', WorkOrders.DateDue) as 'DateDueID',
datediff(dd, '1/1/1950', Detail.DateCompl) as 'DateCompletedID',
datediff(dd, '1/1/1950', WorkOrders.DateSched) as 'DateScheduledID',
isnull(Cast(cast(Company.GLCo as varchar(3))
+cast(Datediff(dd,'1/1/1950',cast(cast(DATEPART(yy,WorkOrders.DateSched) as varchar) 
+ '-'+ DATENAME(m, WorkOrders.DateSched) +'-01' as datetime)) as varchar(10)) as int),0) as FiscalMthID,
Detail.EstHrs,
case 
	when Detail.DateDue <= getdate() then datediff(dd, Detail.DateDue, getdate()) 
end as 'DaysOverDue',
case 
	when Detail.DateDue <= getdate() then 1 else Null
end as 'OverDueCount',
case 
	when Detail.DateSched <= getdate() then datediff(dd, Detail.DateSched, getdate())
end as 'DaysLateScheduled',
case 
	when Detail.DateDue > getdate() then datediff(dd, getdate(),Detail.DateDue)
end as 'DaysUntilDue',
case 
	when Detail.DateSched > getdate() then datediff(dd, getdate(), Detail.DateSched)
end as 'DaysUntilScheduled', ---will return Null if dateSched less than getdate()
case Detail.Priority when 'L' then 1 else 0 end as 'Low',
case Detail.Priority when 'N' then 1 else 0 end as 'Normal',
case Detail.Priority when 'U' then 1 else 0 end as 'Urgent'
FROM bEMWI Detail With (NoLock)
LEFT OUTER JOIN	bEMWH WorkOrders With (NoLock)
		ON  Detail.EMCo = WorkOrders.EMCo
		AND Detail.WorkOrder = WorkOrders.WorkOrder 
LEFT OUTER JOIN	bEMCO Company With (NoLock)
		ON  Detail.EMCo = Company.EMCo
LEFT OUTER JOIN bEMEM Equipment With (NoLock)
		ON  Detail.EMCo			= Equipment.EMCo
		AND Detail.Equipment	= Equipment.Equipment
LEFT OUTER JOIN bEMDM Department With (NoLock)
		ON  Detail.EMCo			 = Department.EMCo
		AND Equipment.Department = Department.Department
LEFT OUTER JOIN  bEMCM Category With (NoLock)
		ON  Detail.EMCo			= Category.EMCo
		AND Equipment.Category	= Category.Category
LEFT OUTER JOIN	bPREH Employee With (NoLock)
		ON  WorkOrders.Mechanic = Employee.Employee
	    and WorkOrders.EMCo = Employee.PRCo
LEFT OUTER JOIN dbo.bEMCC EMCC
	 On Detail.EMGroup = EMCC.EMGroup
	and Detail.CostCode = EMCC.CostCode
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Detail.EMCo
where WorkOrders.Complete = 'N'


GO
GRANT SELECT ON  [dbo].[viFact_EMWorkOrder] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMWorkOrder] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMWorkOrder] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMWorkOrder] TO [public]
GO
