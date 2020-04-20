IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptCrossDepartmentRates]'))
	DROP PROCEDURE [dbo].[mckrptCrossDepartmentRates]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 09/03/2014 Amit Mody			Authored
** 03/02/2015 Amit Mody			Updated joins and added a condition to clean up rows with both 
**								employee parent GL department and job parent GL department as undefined
** 04/02/2015 Amit mody			Supported Employee Group = All (default) and added EmployeeGroup to dataset
***********************************************************************************************************/

CREATE PROCEDURE [dbo].[mckrptCrossDepartmentRates]
	@EmployeeGroup varchar(10) = "All",
	@StartDate datetime = null,
	@EndDate datetime = null
AS
BEGIN

IF ((@StartDate IS NULL) OR (DATEDIFF(DAY, @StartDate, GETDATE()) > 365) OR (@StartDate > GETDATE()))
BEGIN
	SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
END

IF ((@EndDate IS NULL) OR (@EndDate < @StartDate) OR (@EndDate > GETDATE()))
BEGIN
	SET @EndDate = GETDATE()
END

SELECT
	  prgr.Description AS [Payroll Company Code]
,	  emp.GLCo AS EmpCo
,	  emp.Name AS EmpCoDesc
,	  emp.Instance EmpGLDept
,	  emp.Description AS EmpGLDeptDesc
,     CONVERT(VARCHAR(5), emp.Instance) + ' ' + emp.Description AS EmpGLDeptAndDesc
,	  emp.ParentGLDept AS EmpParentGLDept
,	  job.GLCo AS JobCo
,	  job.Name AS JobCoDesc
,	  job.Instance JobGLDept
,	  job.Description AS JobGLDeptDesc
,     CONVERT(VARCHAR(5), job.Instance) + ' ' + job.Description AS JobGLDeptAndDesc
,	  job.ParentGLDept AS JobParentGLDept
,     SUM(prth.Hours) AS TotalHours
,     CASE prgr.Description 
		WHEN 'Staff' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTSTAFF') 
		WHEN 'Union' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTUNION') 
	  END AS EmpGLDeptRate
,     SUM(prth.Hours) * 
	  (CASE prgr.Description 
		WHEN 'Staff' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTSTAFF') 
		WHEN 'Union' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTUNION') 
		ELSE 0
	   END) AS TotalCost
FROM 
      (SELECT PRCo, PRDept, PRGroup, JCCo, JCDept, PREndDate, Hours, Employee
	   FROM	  mvwPRTH 
	   WHERE  PRCo IS NOT NULL 
		  AND PRDept IS NOT NULL 
		  AND PRGroup IS NOT NULL 
		  AND PREndDate IS NOT NULL
		  AND Employee IS NOT NULL
		  AND JCCo IS NOT NULL 
		  AND JCDept IS NOT NULL 
		  AND Hours <> 0
		  AND PRCo < 100
		  AND JCCo < 100) prth JOIN
	  PRGR prgr ON
			prth.PRCo = prgr.PRCo
		AND prth.PRGroup = prgr.PRGroup JOIN
      (SELECT prdp.PRCo, prdp.PRDept, glpi3.GLCo, glpi3.Instance, glpi3.Description, /* ISNULL(udd.ParentGLDept, glpi3.Instance) */ glpi3.Instance AS ParentGLDept, hqco.Name
		 FROM PRDP prdp JOIN
			  GLPI glpi3 ON
				prdp.GLCo=glpi3.GLCo
			  AND glpi3.PartNo=3
			  AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4) JOIN
			  HQCO hqco ON
				glpi3.GLCo = hqco.HQCo 
			  AND hqco.udTESTCo<>'Y' 
			  --LEFT JOIN
			  --udGLDept udd ON 
				--glpi3.GLCo = udd.Co
			  --AND glpi3.Instance = udd.GLDept
			  ) emp ON
			prth.PRCo=emp.PRCo
		AND prth.PRDept=emp.PRDept JOIN
     (SELECT jcdm.JCCo, jcdm.Department, glpi3.GLCo, glpi3.Instance, glpi3.Description, /* ISNULL(udd.ParentGLDept, glpi3.Instance) */ glpi3.Instance AS ParentGLDept, hqco.Name
		FROM JCDM jcdm JOIN
			 GLPI glpi3 ON
				jcdm.GLCo=glpi3.GLCo
			 AND glpi3.PartNo=3
			 AND glpi3.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) JOIN
			 HQCO hqco ON
				glpi3.GLCo = hqco.HQCo 
			 AND hqco.udTESTCo<>'Y' 
			 --LEFT JOIN
			 --udGLDept udd ON 
				--glpi3.GLCo = udd.Co
			 --AND glpi3.Instance = udd.GLDept
			 ) job ON
          prth.JCCo=job.JCCo
      AND prth.JCDept=job.Department 
WHERE
	  --(prth.PRCo <= 100 AND prth.JCCo <= 100)
	  --AND ((emp.ParentGLDept IS NOT NULL AND job.ParentGLDept IS NOT NULL AND emp.ParentGLDept <> job.ParentGLDept) OR (emp.ParentGLDept IS NOT NULL OR job.ParentGLDept IS NOT NULL))
	  emp.ParentGLDept <> job.ParentGLDept
	  --AND (CASE prgr.Description 
			--WHEN 'Staff' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTSTAFF') 
			--WHEN 'Union' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTUNION')
		 --   ELSE 0
		 --  END) <> 0
      AND prth.PREndDate BETWEEN @StartDate AND @EndDate
	  AND (@EmployeeGroup='All' OR prgr.Description = @EmployeeGroup)
GROUP BY
	  emp.GLCo
,	  emp.Name
,	  emp.Instance 
,     emp.Description
,	  emp.ParentGLDept
,	  job.GLCo
,	  job.Name
,     job.Instance 
,     job.Description
,	  job.ParentGLDept
,	  prgr.Description
ORDER BY 1,2,4

END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[mckrptCrossDepartmentRates] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC dbo.mckrptCrossDepartmentRates
--EXEC dbo.mckrptCrossDepartmentRates 'Staff'
--EXEC dbo.mckrptCrossDepartmentRates 'Union', '1/1/2015', '2/1/2015'