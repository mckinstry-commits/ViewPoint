IF OBJECT_ID ('dbo.vwVPJobAllocation', 'view') IS NOT NULL
DROP VIEW dbo.vwVPJobAllocation;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 12/17/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.vwVPJobAllocation
AS
SELECT	jd.EmployeeId
,		jd.JobNumber
,		jd.JobName
,		jd.GLDepartmentNumber
,		jd.GLDepartmentName
,		jd.JobHours
,		js.JobHours AS TotalHours
,		jd.JobHours / js.JobHours AS PercentAlloc
,		jd.MaxEffectiveDate
,		jd.EffectiveYear
,		jd.EffectiveMonth
FROM    (SELECT EmployeeId
		 ,		SUM(JobHours) AS JobHours
		 ,		MAX(EffectiveDate) AS MaxEffectiveDate
		 ,		EffectiveYear
		 ,		EffectiveMonth
		 FROM   dbo.VPEmployeeJobAssignment AS ja
		 GROUP BY 
				EmployeeId
		 ,		EffectiveYear
		 ,		EffectiveMonth
		 HAVING  (SUM(JobHours) <> 0)
		) AS js INNER JOIN
        (SELECT	EmployeeId
		 ,		JobNumber
		 ,		JobName
		 ,		GLDepartmentNumber
		 ,		GLDepartmentName
		 ,		SUM(JobHours) AS JobHours
		 ,		MAX(EffectiveDate) AS MaxEffectiveDate
		 ,		EffectiveYear
		 ,		EffectiveMonth
		 FROM	dbo.VPEmployeeJobAssignment AS ja
		 GROUP BY 
				EmployeeId
		 ,		JobNumber
		 ,		GLDepartmentNumber
		 ,		EffectiveYear
		 ,		EffectiveMonth
		 ,		JobName
		 ,		GLDepartmentName
		 HAVING	(SUM(JobHours) <> 0)
		) AS jd 
		ON	jd.EmployeeId = js.EmployeeId 
		AND jd.EffectiveYear = js.EffectiveYear 
		AND jd.EffectiveMonth = js.EffectiveMonth
GO

GRANT SELECT ON dbo.vwVPJobAllocation TO [public]
GO

-- Test Script
SELECT * FROM dbo.vwVPJobAllocation