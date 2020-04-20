/*
IF  NOT EXISTS (SELECT * FROM sys.columns WHERE Name = N'PRCompanyNumber' and Object_ID = Object_ID(N'EmployeeJobAssignment'))
	ALTER TABLE dbo.EmployeeJobAssignment
	ADD PRCompanyNumber int NULL
GO

IF  NOT EXISTS (SELECT * FROM sys.columns WHERE Name = N'GLCompanyNumber' and Object_ID = Object_ID(N'EmployeeJobAssignment'))
	ALTER TABLE dbo.EmployeeJobAssignment
	ADD GLCompanyNumber int NULL
GO
*/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spGetVPJobAssignment]'))
	DROP PROCEDURE [dbo].[spGetVPJobAssignment]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 08/28/2014 Amit Mody			Authored
** 12/16/2014 Amit Mody			Fixed lengths of JobName, PRDepartmentName and GLDepartmentName fields to match with EmployeeJobAssignment table schema
***********************************************************************************************************/

CREATE PROCEDURE [dbo].[spGetVPJobAssignment]
	@StartDate INT = NULL ,
    @EndDate INT = NULL
AS
BEGIN
    IF @StartDate IS NULL 
        SELECT  @StartDate = 20070101

    IF @EndDate IS NULL 
        SELECT  @EndDate = CAST(CONVERT(VARCHAR(10), GETDATE(), 112) AS INT)

    DECLARE @dtmStartDate DATETIME
    DECLARE @dtmEndDate DATETIME

    SET @dtmStartDate =  CONVERT(DATETIME, CONVERT(varchar(8), @StartDate))
    SET @dtmEndDate =  CONVERT(DATETIME, CONVERT(varchar(8), @EndDate))

    DELETE FROM VPEmployeeJobAssignment
    WHERE EffectiveDate BETWEEN @dtmStartDate AND @dtmEndDate

	INSERT INTO VPEmployeeJobAssignment
	SELECT
		  prth.Employee AS EmployeeId
	,	  prth.Job AS JobNumber
	,	  SUBSTRING(jcjm.Description,0,50) AS JobName
	,	  glpi3.Instance AS PRDepartmentNumber 
	,	  SUBSTRING(glpi3.Description,0,50) AS PRDepartmentName
	,	  glpi3_2.Instance AS GLDepartmentNumber 
	,	  SUBSTRING(glpi3_2.Description,0,50) AS GLDepartmentName
	,	  sum(prth.Hours) AS JobHours
	,     prth.PREndDate AS EffectiveDate
	from 
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].bPRTH prth JOIN
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].PRDP prdp ON
				prth.PRCo=prdp.PRCo
		  AND prth.PRDept=prdp.PRDept LEFT OUTER JOIN
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].JCJM jcjm ON
				jcjm.JCCo=prth.JCCo 
		  AND jcjm.Job=prth.Job LEFT OUTER JOIN
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].GLPI glpi3 ON
				prth.PRCo=glpi3.GLCo
		  AND glpi3.PartNo=3
		  AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4) JOIN
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].JCDM jcdm ON
				prth.JCCo=jcdm.JCCo
		  AND prth.JCDept=jcdm.Department  LEFT OUTER JOIN
		  [ViewpointAG\Viewpoint].[Viewpoint].[dbo].GLPI glpi3_2 ON
				prth.JCCo=glpi3_2.GLCo
		  AND glpi3_2.PartNo=3
		  AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4) 
	WHERE
		  prth.PREndDate BETWEEN @dtmStartDate AND @dtmEndDate
		  AND glpi3.Instance IS NOT NULL
	GROUP BY 
		  prth.Employee
	,	  prth.Job
	,	  jcjm.Description
	,	  glpi3.Instance
	,	  glpi3.Description
	,	  glpi3_2.Instance
	,	  glpi3_2.Description
	,     prth.PREndDate
END
GO

--Test script

--EXEC dbo.spGetVPJobAssignment
--select * from VPEmployeeJobAssignment

--EXEC dbo.spGetVPJobAssignment 20141101, 20141130
--select * from VPEmployeeJobAssignment