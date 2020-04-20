SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[fn_McK_PayrollHourSummary]
(
	
)
RETURNS @resultsTbl TABLE
(	
	PRCo	[dbo].[bCompany] null
,	PRGroup		[dbo].bGroup null
,	PREndDate	[dbo].bDate null
,	PRDept		[dbo].bDept null
,	PRDeptDesc	[dbo].bDesc null
,	Employee	[dbo].bEmployee	null
,	LastName	VARCHAR(30) null
,	FirstName	VARCHAR(30) NULL
,	JCCo		dbo.bCompany null
,	JCDept		[dbo].bDept null
,	Job			dbo.bJob null
,	EarnCode	VARCHAR(30) null
,	TotalHours	DECIMAL(8,2) null
,	RegHours	DECIMAL(8,2) null
,	OTHours		DECIMAL(8,2) null
,	OtherHours	DECIMAL(8,2) null
)
AS
BEGIN 
	
	INSERT 	@resultsTbl
	(
		PRCo
	,	PRGroup
	,	PREndDate
	,	PRDept
	,	PRDeptDesc
	,	Employee
	,	LastName
	,	FirstName
	,	JCCo
	,	JCDept
	,	Job	
	,	EarnCode
	,	TotalHours
	,	RegHours
	,	OTHours
	,	OtherHours
	)
	SELECT
			t1.PRCo
		,	t1.PRGroup
		,	t1.PREndDate
		,	e.PRDept
		,	d.Description AS PRDeptDesc
		,	t1.Employee
		,	e.LastName
		,	e.FirstName
		,	t1.JCCo
		,	t1.JCDept
		,	t1.Job
		,	CASE 
				WHEN t2.Description not IN ('Regular','Overtime') THEN 'Other:' + t2.Description
				ELSE t2.Description
			END AS EarnCode
		,	SUM(t1.Hours) AS TotalHours
		,	CASE 
				WHEN t2.Description='Regular' THEN SUM(t1.Hours)
				ELSE 0
			END AS RegHours
		,	CASE 
				WHEN t2.Description='Overtime' THEN SUM(t1.Hours)
				ELSE 0
			END AS OTHours
		,	CASE 
				WHEN t2.Description not IN ('Regular','Overtime') THEN CAST(SUM(t1.Hours) AS DECIMAL(8,2))
				ELSE 0
			END AS OtherHours
		FROM
			dbo.PRTH t1 LEFT OUTER JOIN
			dbo.PREC t2 ON 
				t1.EarnCode=t2.EarnCode 
			AND t1.PRCo=t2.PRCo LEFT OUTER JOIN 
			--AND t1.PRGroup=t2.PRGroup 
			dbo.PREH e ON
				t1.PRCo=e.PRCo
			AND t1.Employee=e.Employee
			AND t1.PRGroup=e.PRGroup LEFT OUTER JOIN
			dbo.PRDP d ON
				e.PRCo=d.PRCo
			AND e.PRDept=d.PRDept				
		GROUP BY
			t1.PRCo
		,	t1.PRGroup
		,	t1.PREndDate
		,	e.PRDept
		,	d.Description
		,	t1.Employee
		,	e.LastName
		,	e.FirstName		
		,	t1.JCCo
		,	t1.JCDept
		,	t1.Job
		,	t2.Description	
		--HAVING
		--	SUM(t1.Hours) <> 0					
		
	RETURN
END

GO
GRANT SELECT ON  [dbo].[fn_McK_PayrollHourSummary] TO [public]
GO
