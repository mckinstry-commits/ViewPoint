USE Viewpoint
GO

DECLARE @Utilization TABLE(Co bCompany, Employee bEmployee, UtilMth bMonth, URate NUMERIC(10,0))

INSERT INTO @Utilization
        ( Co, Employee, UtilMth, URate )
SELECT
      CASE p.MCONO 
            WHEN 15 THEN 1
            WHEN 50 THEN 1
            ELSE p.MCONO 
      END   AS Company, p.MEENO AS Employee, CAST(LTRIM(RTRIM(h.VFSBCT)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) AS UtilizationMonth , h.VF06P1 AS UtilizationRate
from 
      CMS.S1017192.CMSFIL.PRPMST p JOIN
      CMS.S1017192.CMSFIL.SYSUHREMP h ON
            p.MCONO = h.VFCONO
      AND   p.MDVNO = h.VFDVNO
      AND   p.MSSNO = h.VFSSNO
      AND p.MCONO IN (1,15,20,30,50,60)
	  AND MSTAT<>'I'
--WHERE p.MSTAT='A'
--WHERE p.MEENO=157
ORDER BY
      p.MCONO, p.MEENO, h.VFSBCT


SELECT a.Co,a.Employee AS InvalidEmployees, b.MCONO, b.MNM25, b.MSTAT, e.LastName
FROM 
	(SELECT  Co , Employee--, UtilMth, URate 
	FROM @Utilization
	GROUP BY Co, Employee) a
	LEFT OUTER JOIN 
	(SELECT PRCo,Employee, ActiveYN, LastName FROM dbo.PREH) e ON a.Co=e.PRCo AND a.Employee = e.Employee 
	LEFT OUTER JOIN CMS.S1017192.CMSFIL.PRPMST b ON /*a.Co = b.MCONO AND*/ a.Employee = b.MEENO
WHERE e.Employee IS NULL OR e.ActiveYN = 'N'

--SELECT * FROM PREH 
--WHERE Employee = 249


