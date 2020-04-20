IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptCrossDepartmentRateDetails]'))
	DROP PROCEDURE [dbo].[mckrptCrossDepartmentRateDetails]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 09/18/2014 Amit Mody			Authored
** 03/02/2015 Amit Mody			Updated joins and added a condition to clean up rows with both 
**								employee parent GL department and job parent GL department as undefined
** 04/02/2015 Amit mody			Supported Employee Group = All (default)
***********************************************************************************************************/

CREATE PROCEDURE [dbo].[mckrptCrossDepartmentRateDetails]
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

DECLARE @RateType VARCHAR(10)
SELECT @RateType = CASE @EmployeeGroup WHEN 'Staff' THEN 'XDEPTSTAFF' WHEN 'Union' THEN 'XDEPTUNION' END

SELECT
	  emp.GLCo AS [Home Company Number]
,	  emp.Name AS [Home Company Name]
,	  ISNULL(preh.[LastName] + ', ', '') + ISNULL(preh.[FirstName] + ' ', '') + ISNULL(preh.[MidName], '') AS [Employee Name]
,     ISNULL(prth.Class, '') AS Class
,	  ISNULL(prth.Craft, '') AS Craft
,     prgr.Description AS [Employee Group]
,	  emp.Instance [Home BU]
,	  emp.Description AS [Home BU Description]
,	  emp.ParentGLDept AS [Home Parent BU]
,	  ISNULL(jcjm.Job, '') AS [Job #]
,	  ISNULL(jcjm.Description, '') AS [Job Description]
,	  job.GLCo AS [Jobs Company]
,	  job.Name AS [Jobs Company Name]
,	  job.Instance [Jobs BU]
,	  job.Description AS [Jobs BU Description]
,	  job.ParentGLDept AS [Jobs Parent BU]
,	  MONTH(prth.PREndDate) AS [Month]
,	  YEAR(prth.PREndDate) AS [Year]
,     SUM(prth.Hours) AS [Total Hours]
,     CASE prgr.Description 
		WHEN 'Staff' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTSTAFF') 
		WHEN 'Union' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTUNION') 
	  END AS [Home BU Rate]
,     SUM(prth.Hours) * 
	  (CASE prgr.Description 
		WHEN 'Staff' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTSTAFF') 
		WHEN 'Union' THEN dbo.fnGetEffectiveDepartmentRate (emp.GLCo, emp.Instance, 'XDEPTUNION') 
		ELSE 0
	   END) AS [Total Cost]
FROM  
       (SELECT PRCo, PRDept, PRGroup, JCCo, JCDept, PREndDate, Hours, Employee, Job, Class, Craft
	    FROM   mvwPRTH 
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
      AND prth.JCDept=job.Department LEFT JOIN
	  PREHName preh ON
          prth.PRCo=preh.PRCo
      AND prth.Employee=preh.Employee LEFT JOIN
	  JCJM jcjm ON
		  jcjm.JCCo=prth.JCCo
	  AND jcjm.Job=prth.Job
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
,	  preh.LastName
,	  preh.FirstName
,	  preh.MidName
,	  prth.PREndDate
,     prth.Class
,	  prth.Craft
,     prgr.Description
,	  emp.Instance 
,     emp.Description
,	  jcjm.Job
,	  jcjm.Description
,	  emp.ParentGLDept
,	  job.GLCo
,	  job.Name
,     job.Instance 
,     job.Description
,	  job.ParentGLDept

END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[mckrptCrossDepartmentRateDetails] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC dbo.mckrptCrossDepartmentRateDetails
--EXEC dbo.mckrptCrossDepartmentRateDetails 'Staff'
--EXEC dbo.mckrptCrossDepartmentRateDetails 'Union'