IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptEmployeeHoursByGLDepartmentNoPivot]'))
	DROP PROCEDURE [dbo].[mckrptEmployeeHoursByGLDepartmentNoPivot]
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 08/20/2014 Amit Mody			Authored
** 08/22/2014 Amit Mody			Added Department IDs in description
** 
******************************************************************************/

CREATE PROCEDURE [dbo].[mckrptEmployeeHoursByGLDepartmentNoPivot]
	@EmpGlDeptIds varchar(1024) = null,
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
	  convert(varchar(5), glpi3.Instance) + ' ' + glpi3.Description AS EmpGLDeptDesc
,     SUBSTRING(CONVERT(nvarchar(30),prth.PREndDate,23), 1, 7) AS WeekEndingMonthYear
,	  convert(char(1), dbo.fnPayrollPeriodsOfMonth(prth.PREndDate)) AS NumPayrollPeriods
,     prth.Craft + ' ' + prcm.Description AS Craft
,	  prth.Class + ' ' + prcc.Description AS Class
,     prgr.Description AS EmployeeGroup
,     SUM(prth.Hours) AS TotalHours
from 
      PRTH prth JOIN
      PREHName preh ON 
            prth.PRCo=preh.PRCo
      AND prth.Employee=preh.Employee join
      PRDP prdp ON
            prth.PRCo=prdp.PRCo
      AND prth.PRDept=prdp.PRDept LEFT OUTER JOIN
      GLPI glpi3 ON
            prth.PRCo=glpi3.GLCo
      AND glpi3.PartNo=3
      AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4) JOIN
      JCDM jcdm ON
            prth.JCCo=jcdm.JCCo
      AND prth.JCDept=jcdm.Department  LEFT OUTER JOIN
      GLPI glpi3_2 ON
            prth.JCCo=glpi3_2.GLCo
      AND glpi3_2.PartNo=3
      AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4) LEFT OUTER JOIN
	  PRCM prcm ON 
			prth.Craft=prcm.Craft 
	  AND prth.PRCo=prcm.PRCo LEFT OUTER JOIN 
	  PRCC prcc ON 
			prth.Class=prcc.Class
	  AND prth.PRCo=prcc.PRCo LEFT OUTER JOIN
	  PRGR prgr ON
			prth.PRCo = prgr.PRCo
	  AND prth.PRGroup = prgr.PRGroup 
WHERE
	  @EmpGlDeptIds LIKE '%|' + SUBSTRING(glpi3.Instance,1,4) + '|%'
	  AND prth.PREndDate BETWEEN @StartDate AND @EndDate
GROUP BY
      prth.PRCo
,     prth.Employee
,     preh.FirstName
,     preh.LastName
,     prth.Craft
,     prcm.Description
,     prth.Class
,     prcc.Description
,     prth.PRDept
,     prdp.Description
,     glpi3.Instance 
,     glpi3.Description
,     prth.PRGroup
,	  prth.PREndDate
,     prth.Job
,     prth.JCDept
,     jcdm.Description
,     glpi3_2.Instance 
,     glpi3_2.Description
,     prgr.Description 

END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[mckrptEmployeeHoursByGLDepartmentNoPivot] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot null, '01/01/2013', '06/30/2013'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', null, '04/30/2014'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', '08/01/2014', '04/30/2014'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', '01/01/2015', '12/31/2015'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', '2/28/2014', '05/31/2014'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot null, '08/20/2013', null
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', '09/01/2013', '08/31/2014'
--EXEC dbo.mckrptEmployeeHoursByGLDepartmentNoPivot '|0201|0207|0220|0230|0260|0008|0002|0100|0520|0000|', '12/01/2013', '12/31/2013'