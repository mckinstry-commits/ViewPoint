USE Viewpoint
GO


DECLARE @Utilization TABLE(Co bCompany, Employee bEmployee, UtilMth bMonth, URate NUMERIC(20,10))

INSERT INTO @Utilization
        ( Co, Employee, UtilMth, URate )
SELECT
      CASE p.MCONO 
            WHEN 15 THEN 1
            WHEN 50 THEN 1
            ELSE p.MCONO 
      END   AS Company, p.MEENO AS Employee, CAST(LTRIM(RTRIM(h.VFSBCT)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) AS UtilizationMonth , (h.VF06P1)/100 AS UtilizationRate
from 
      CMS.S1017192.CMSFIL.PRPMST p JOIN
      CMS.S1017192.CMSFIL.SYSUHREMP h ON
            p.MCONO = h.VFCONO
      AND   p.MDVNO = h.VFDVNO
      AND   p.MSSNO = h.VFSSNO
      AND p.MCONO IN (1,15,20,30,50,60)
      AND MSTAT<>'I'
--WHERE p.MEENO=157
ORDER BY
      p.MCONO, p.MEENO, h.VFSBCT

--SELECT * FROM @Utilization


--validations
--SELECT a.Co,a.Employee AS InvalidEmployees FROM 
--	(SELECT  Co , Employee--, UtilMth, URate 
--	FROM @Utilization
--	GROUP BY Co, Employee) a
--	LEFT OUTER JOIN 
--	(SELECT PRCo,Employee, ActiveYN FROM dbo.PREH) e ON a.Co=e.PRCo AND a.Employee = e.Employee 
--WHERE e.Employee IS NULL OR e.ActiveYN = 'N'
----UNION ALL
--SELECT COUNT(*) AS ValidEmployees FROM 
--	(SELECT  Co , Employee--, UtilMth, URate 
--	FROM @Utilization
--	GROUP BY Co, Employee) a
--	LEFT OUTER JOIN 
--	(SELECT PRCo,Employee, ActiveYN FROM dbo.PREH) e ON a.Co=e.PRCo AND a.Employee=e.Employee
--WHERE e.Employee IS NOT NULL AND ActiveYN='Y'

/* --COMMENTED OUT TO PREVENT ACCIDENTAL INSERT BEFORE WE'RE READY.*/
INSERT INTO dbo.udEmpUtilization
        ( Co ,
          Employee ,
		  Year ,
		  Jan ,Feb ,Mar ,
          Apr ,May ,Jun ,Jul ,
          Aug ,Sep,Oct ,
          Nov ,Dec 
          --,
		  --AnnualPct ,
          --Q1 ,
          --Q2 ,
          --Q3 ,
          --Q4 ,
          --UniqueAttchID
        )
SELECT * 
FROM (SELECT Co, Employee, 2014 AS [Year] , UtilMth, URate 
		FROM @Utilization) AS SourceTable
PIVOT
	(MAX(URate) FOR UtilMth IN ([2014-01-01 00:00:00],[2014-02-01 00:00:00],[2014-03-01 00:00:00],[2014-04-01 00:00:00],[2014-05-01 00:00:00],[2014-06-01 00:00:00]
	,[2014-07-01 00:00:00],[2014-08-01 00:00:00],[2014-09-01 00:00:00],[2014-10-01 00:00:00],[2014-11-01 00:00:00],[2014-12-01 00:00:00])
	) AS PivotTable

