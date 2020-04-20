USE [Viewpoint]
GO
/****** Object:  UserDefinedFunction [dbo].[mfnBenefitEligibleEmployeesFromVP]    Script Date: 11/02/2014 08:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[mfnBenefitEligibleEmployeesFromVP]
(
	@periodEnding DATETIME
)
RETURNS TABLE 
AS
RETURN
--select @periodEnding='9/8/2013'
SELECT
	REPLICATE('0',9-LEN(preh.Employee)) + CAST(preh.Employee AS VARCHAR(10)) AS EmployeeNumber
,	preh.LastName
,	preh.FirstName
,	preh.Address
,	preh.Address2
,	preh.City
,	preh.State
,	preh.Zip
,	preh.BirthDate
,	preh.HireDate
,	prdp.PRDept
,	prdp.Description AS PRDeptDesc
,	prdp.JCFixedRateGLAcct
,	CAST(preh.PRCo AS VARCHAR(3)) + '.' + glpi.Instance AS GLDepartment
,	glpi.Description AS GLDepartmentDesc
,	prth.PREndDate AS PeriodEnding
,	SUM(prth.Hours) AS PeriodHours
FROM 
	bPREH preh JOIN
	bPRGR prgr ON
		preh.PRCo=prgr.PRCo
	AND	preh.PRGroup=prgr.PRGroup JOIN
	bPRTH prth ON
		preh.PRCo=prth.PRCo
	AND	preh.PRGroup=prth.PRGroup
	AND preh.Employee=prth.Employee JOIN
	bPRDP prdp ON
		preh.PRCo=prdp.PRCo
	AND preh.PRDept=prdp.PRDept JOIN
	GLPI glpi ON
		preh.PRCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
WHERE
	preh.ActiveYN='Y'
AND prgr.Description='Staff'
AND	( prth.PREndDate=@periodEnding OR @periodEnding IS NULL)
AND prth.PRCo < 100
GROUP BY
	preh.Employee
,	preh.LastName
,	preh.FirstName
,	preh.Address
,	preh.Address2
,	preh.City
,	preh.State
,	preh.Zip
,	preh.BirthDate
,	preh.HireDate
,	preh.PRCo
,	prdp.PRDept
,	prdp.Description
,	prdp.JCFixedRateGLAcct
,	glpi.Instance
,	glpi.Description
,	prth.PREndDate
HAVING
	SUM(prth.Hours) >=30

