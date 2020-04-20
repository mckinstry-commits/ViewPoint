SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viFact_EMRevenue] AS

/**************************************************
 * ALTERd: TMS 2009-06-15
 * Modified:    MB 8/19/09  
 * Usage:  Fact View returning EM Revenue detail 
 *		   from EMRD for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	Company.KeyID		AS 'EMCoID'
,	Department.KeyID	AS 'DepartmentID'
,	Category.KeyID		AS 'CategoryID'
,	Equipment.KeyID		AS 'EquipmentID'
,	RevenueCode.KeyID	AS 'RevenueCodeID'
,	Job.KeyID			AS 'JobID'
,	isnull(Cast(cast(FiscalMonth.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',FiscalMonth.Mth) as varchar(10)) as int),0) as 'FiscalMthID'
,	datediff(dd, '1/1/1950', PostDate)		AS 'PostedDateID'
,	datediff(dd, '1/1/1950', ActualDate)	AS 'ActualDateID'
--,	Case When Sum(HrsPerTimeUM) = 0 Then 0 Else Sum(TimeUnits) / Sum(HrsPerTimeUM) End AS 'Hours'
,   sum(TimeUnits * HrsPerTimeUM) as 'Hours'
,	Sum(Detail.Dollars) AS 'Revenue'
,	sum(isnull(Detail.HourReading, 0) - isnull(Detail.PreviousHourReading, 0)) as 'RevenueHourReading'
FROM bEMRD Detail 
LEFT OUTER JOIN bEMCO Company 
	ON  Detail.EMCo = Company.EMCo
LEFT OUTER JOIN bEMEM Equipment 
	ON  Detail.EMCo			= Equipment.EMCo
	AND Detail.Equipment	= Equipment.Equipment
LEFT OUTER JOIN bEMDM Department 
	ON  Detail.EMCo			 = Department.EMCo
	AND Equipment.Department = Department.Department
LEFT OUTER JOIN  bEMCM Category 
	ON  Detail.EMCo			= Category.EMCo
	AND Equipment.Category	= Category.Category
LEFT OUTER JOIN bJCJM Job 
	ON  Detail.JCCo = Job.JCCo
	AND Detail.Job = Job.Job
LEFT OUTER JOIN bEMRC RevenueCode 
	ON  Detail.EMGroup = RevenueCode.EMGroup
	AND Detail.RevCode = RevenueCode.RevCode
LEFT OUTER JOIN bGLFP FiscalMonth 
	ON FiscalMonth.GLCo=isnull(Detail.GLCo,Company.GLCo)
	AND FiscalMonth.Mth=Detail.Mth
Inner Join vDDBICompanies ON vDDBICompanies.Co=Detail.EMCo
GROUP BY
	Company.KeyID 
,	Department.KeyID 
,	Category.KeyID 
,	Equipment.KeyID 
,	RevenueCode.KeyID 
,	Job.KeyID
,	FiscalMonth.GLCo
,	FiscalMonth.Mth 
,	datediff(dd, '1/1/1950', PostDate) 
,	datediff(dd, '1/1/1950', ActualDate)


GO
GRANT SELECT ON  [dbo].[viFact_EMRevenue] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMRevenue] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMRevenue] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMRevenue] TO [public]
GRANT SELECT ON  [dbo].[viFact_EMRevenue] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_EMRevenue] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_EMRevenue] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_EMRevenue] TO [Viewpoint]
GO
