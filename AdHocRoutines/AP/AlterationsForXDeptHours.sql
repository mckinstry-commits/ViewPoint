if exists (select 1 from sysobjects where name='mvwPRTH' and type = 'V')
begin
	print 'alter view mvwPRTH'
end
go

ALTER VIEW mvwPRTH
AS 
SELECT  PRCo ,
        PRGroup ,
        PREndDate ,
        Employee ,
        PaySeq ,
        PostSeq ,
        Type ,
        PostDate ,
        JCCo ,
        Job ,
        PhaseGroup ,
        Phase ,
        JCDept ,
        GLCo ,
        EMCo ,
        WO ,
        WOItem ,
        Equipment ,
        EMGroup ,
        CostCode ,
        CompType ,
        Component ,
        RevCode ,
        EquipCType ,
        UsageUnits ,
        TaxState ,
        LocalCode ,
        UnempState ,
        InsState ,
        InsCode ,
        PRDept ,
        Crew ,
        Cert ,
        Craft ,
        Class ,
        EarnCode ,
        Shift ,
        Hours ,
        --Rate ,
        --Amt ,
        InUseBatchId ,
        BatchId ,
        Memo ,
        UniqueAttchID ,
        EquipPhase ,
        KeyID ,
        SMCo ,
        SMWorkOrder ,
        SMScope ,
        SMPayType ,
        SMCostType ,
        SMJCCostType ,
        SMPhaseGroup ,
        PRTBKeyID ,
        udPaidDate ,
        udCMCo ,
        udCMAcct ,
        udCMRef ,
        udTCSource ,
        udSchool ,
        udSource ,
        udConv ,
        udCGCTable ,
        udCGCTableID ,
        udArea ,
        udAsteaDemandId
FROM dbo.bPRTH
go

grant select on mvwPRTH to public
go



if exists (select 1 from sysobjects where name='mckrptCrossDepartmentRates' and type = 'P')
begin
	print 'alter procedure mckrptCrossDepartmentRates'
end
go

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 09/03/2014 Amit Mody			Authored
** 11/24/2014 LWO				Modified to use mvwPRTH
**
***********************************************************************************************************/

ALTER PROCEDURE [dbo].[mckrptCrossDepartmentRates]
	@EmployeeGroup varchar(10) = "Staff",
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
	  glpi3.GLCo AS EmpCo
,	  hqco.Name AS EmpCoDesc
,	  glpi3.Instance EmpGLDept
,	  glpi3.Description AS EmpGLDeptDesc
,     CONVERT(VARCHAR(5), glpi3.Instance) + ' ' + glpi3.Description AS EmpGLDeptAndDesc
,	  udd.ParentGLDept AS EmpParentGLDept
,	  glpi3_2.GLCo AS JobCo
,	  hqco_2.Name AS JobCoDesc
,	  glpi3_2.Instance JobGLDept
,	  glpi3_2.Description AS JobGLDeptDesc
,     CONVERT(VARCHAR(5), glpi3_2.Instance) + ' ' + glpi3_2.Description AS JobGLDeptAndDesc
,	  udd_2.ParentGLDept AS JobParentGLDept
,     SUM(prth.Hours) AS TotalHours
,     dbo.fnGetEffectiveDepartmentRate (glpi3.GLCo, glpi3.Instance, @RateType) AS EmpGLDeptRate
,     SUM(prth.Hours) * dbo.fnGetEffectiveDepartmentRate (glpi3.GLCo, glpi3.Instance, @RateType) AS TotalCost
FROM 
      mvwPRTH prth LEFT OUTER JOIN
      PRDP prdp ON
            prth.PRCo=prdp.PRCo
      AND prth.PRDept=prdp.PRDept LEFT OUTER JOIN
      GLPI glpi3 ON
            prth.PRCo=glpi3.GLCo
      AND glpi3.PartNo=3
      AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4) LEFT OUTER JOIN
	  udGLDept udd ON 
			glpi3.GLCo = udd.Co
	  AND glpi3.Instance = udd.GLDept LEFT OUTER JOIN
	  HQCO hqco ON
			glpi3.GLCo = hqco.HQCo LEFT OUTER JOIN
      JCDM jcdm ON
            prth.JCCo=jcdm.JCCo
      AND prth.JCDept=jcdm.Department LEFT OUTER JOIN
      GLPI glpi3_2 ON
            prth.JCCo=glpi3_2.GLCo
      AND glpi3_2.PartNo=3
      AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4) LEFT OUTER JOIN
	  udGLDept udd_2 ON 
			glpi3_2.GLCo = udd_2.Co
	  AND glpi3_2.Instance = udd_2.GLDept LEFT OUTER JOIN
	  HQCO hqco_2 ON
			glpi3_2.GLCo = hqco_2.HQCo LEFT OUTER JOIN
	  PRGR prgr ON
			prth.PRCo = prgr.PRCo
	  AND prth.PRGroup = prgr.PRGroup
WHERE
	  PREndDate BETWEEN @StartDate AND @EndDate
	  AND prgr.Description = @EmployeeGroup
	  --AND glpi3.Instance <> glpi3_2.Instance
	  AND (udd.ParentGLDept IS NULL 
			OR udd_2.ParentGLDept IS NULL 
			OR udd.ParentGLDept <> udd_2.ParentGLDept)
GROUP BY
	  glpi3.GLCo
,	  hqco.Name
,	  glpi3.Instance 
,     glpi3.Description
,	  udd.ParentGLDept
,	  glpi3_2.GLCo
,	  hqco_2.Name
,     glpi3_2.Instance 
,     glpi3_2.Description
,	  udd_2.ParentGLDept

END

go

grant exec on mckrptCrossDepartmentRates to public
go

if exists (select 1 from sysobjects where name='mckrptCrossDepartmentRateDetails' and type = 'P')
begin
	print 'alter procedure mckrptCrossDepartmentRateDetails'
end
go


/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 09/18/2014 Amit Mody			Authored
** 11/24/2014 LWO				Modified to use mvwPRTH
**
***********************************************************************************************************/

alter PROCEDURE [dbo].[mckrptCrossDepartmentRateDetails]
	@EmployeeGroup varchar(10) = "Staff",
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
	  glpi3.GLCo AS [Home Company Number]
,	  hqco.Name AS [Home Company Name]
,	  preh.[LastName] + ', ' + preh.[FirstName] + ' ' + preh.[MidName] AS [Employee Name]
,     prth.Class
,	  prth.Craft
,     prgr.Description AS [Employee Group]
,	  glpi3.Instance [Home BU]
,	  glpi3.Description AS [Home BU Description]
,	  udd.ParentGLDept AS [Home Parent BU]
,	  jcjm.Job AS [Job #]
,	  jcjm.Description AS [Job Description]
,	  glpi3_2.GLCo AS [Jobs Company]
,	  hqco_2.Name AS [Jobs Company Name]
,	  glpi3_2.Instance [Jobs BU]
,	  glpi3_2.Description AS [Jobs BU Description]
,	  udd_2.ParentGLDept AS [Jobs Parent BU]
,	  MONTH(prth.PREndDate) AS [Month]
,	  YEAR(prth.PREndDate) AS [Year]
,     SUM(prth.Hours) AS [Total Hours]
,     dbo.fnGetEffectiveDepartmentRate (glpi3.GLCo, glpi3.Instance, @RateType) AS [Home BU Rate]
,     SUM(prth.Hours) * dbo.fnGetEffectiveDepartmentRate (glpi3.GLCo, glpi3.Instance, @RateType) AS [Total Cost]
FROM 
      mvwPRTH prth LEFT OUTER JOIN
	  PREHName preh ON 
            prth.PRCo=preh.PRCo
      AND prth.Employee=preh.Employee LEFT OUTER JOIN
      PRDP prdp ON
            prth.PRCo=prdp.PRCo
      AND prth.PRDept=prdp.PRDept LEFT OUTER JOIN
	  JCJM jcjm ON
			jcjm.JCCo=prth.JCCo
	  AND jcjm.Job=prth.Job LEFT OUTER JOIN
      GLPI glpi3 ON
            prth.PRCo=glpi3.GLCo
      AND glpi3.PartNo=3
      AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4) LEFT OUTER JOIN
	  udGLDept udd ON 
			glpi3.GLCo = udd.Co
	  AND glpi3.Instance = udd.GLDept LEFT OUTER JOIN
	  HQCO hqco ON
			glpi3.GLCo = hqco.HQCo LEFT OUTER JOIN
      JCDM jcdm ON
            prth.JCCo=jcdm.JCCo
      AND prth.JCDept=jcdm.Department LEFT OUTER JOIN
      GLPI glpi3_2 ON
            prth.JCCo=glpi3_2.GLCo
      AND glpi3_2.PartNo=3
      AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4) LEFT OUTER JOIN
	  udGLDept udd_2 ON 
			glpi3_2.GLCo = udd_2.Co
	  AND glpi3_2.Instance = udd_2.GLDept LEFT OUTER JOIN
	  HQCO hqco_2 ON
			glpi3_2.GLCo = hqco_2.HQCo LEFT OUTER JOIN
	  PRGR prgr ON
			prth.PRCo = prgr.PRCo
	  AND prth.PRGroup = prgr.PRGroup
WHERE
	  PREndDate BETWEEN @StartDate AND @EndDate
	  AND prgr.Description = @EmployeeGroup
	  --AND glpi3.Instance <> glpi3_2.Instance
	  AND (udd.ParentGLDept IS NULL 
			OR udd_2.ParentGLDept IS NULL 
			OR udd.ParentGLDept <> udd_2.ParentGLDept)
GROUP BY
	  glpi3.GLCo
,	  hqco.Name
,	  preh.LastName
,	  preh.FirstName
,	  preh.MidName
,	  prth.PREndDate
,     prth.Class
,	  prth.Craft
,     prgr.Description
,	  glpi3.Instance 
,     glpi3.Description
,	  jcjm.Job
,	  jcjm.Description
,	  udd.ParentGLDept
,	  glpi3_2.GLCo
,	  hqco_2.Name
,     glpi3_2.Instance 
,     glpi3_2.Description
,	  udd_2.ParentGLDept

END

go

grant exec on mckrptCrossDepartmentRateDetails to public
go
