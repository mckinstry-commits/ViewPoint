--SELECT  * from  [MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.mvwPRTH order by Hours desc
SELECT 
	CAST(prth.PRCo AS DECIMAL(3,0)) AS CHCONO
,	CAST(0 AS DECIMAL(3,0)) AS CHDVNO
,	CAST(prth.Employee AS DECIMAL(10,0)) AS CHEENO
,	LEFT(preh.LastName + ', ' + preh.FirstName,25) AS MNM25
,	CAST(COALESCE(CONVERT(CHAR(8),preh.HireDate, 112),0) AS DECIMAL(8,0)) AS MDTHR 
,	CAST(COALESCE(CONVERT(CHAR(8),preh.RecentRehireDate,112),0) AS DECIMAL(8,0)) AS MDTBG
,	CAST(COALESCE(CONVERT(CHAR(8),preh.TermDate, 112),0) AS DECIMAL(8,0)) AS MDTTE
,	CAST(COALESCE(CONVERT(CHAR(8),(SELECT MAX(t1.PostDate) FROM [MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.mvwPRTH t1 WHERE t1.PRCo=prth.PRCo AND t1.Employee=prth.Employee), 112),0)  AS DECIMAL(8,0)) AS MDTWK
,	CASE WHEN preh.ActiveYN='Y' THEN 'A' ELSE 'I' END  AS MSTAT
,	cast(CASE 
		WHEN hqet.Description IN ('Standard Earnings') THEN SUM(prth.Hours)
		ELSE 0
	END AS decimal(8,2)) AS CHRGHR
,	cast(CASE 
		WHEN hqet.Description IN ('Overtime Earnings') THEN SUM(prth.Hours)
		ELSE 0
	END AS decimal(8,2)) AS CHOVHR
,	cast(CASE 
		WHEN hqet.Description IN ('Other Earnings') THEN SUM(prth.Hours)
		ELSE 0
	END AS decimal(8,2)) AS CHOTHR
--,	CAST(ecm.ShortCode AS CHAR(2)) AS CHOTTY	
,	CAST(SUM(prth.HOURS) AS DECIMAL(7,2)) AS CHTLHR
,	CAST(COALESCE(CONVERT(CHAR(8),prth.PREndDate, 112),0) AS DECIMAL(8,0)) AS CHDTWE
,   CAST(prth.Craft AS VARCHAR(10)) AS CHUNNO
,	CAST(prth.udArea AS DECIMAL(3,0)) AS CHCRNO
FROM 
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.mvwPRTH prth JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.bPREH preh ON
		prth.PRCo=preh.PRCo
	AND prth.PRGroup=preh.PRGroup
	AND prth.Employee=preh.Employee JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PREC prec ON
		prth.PRCo=prec.PRCo
	AND prth.EarnCode=prec.EarnCode JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.HQET hqet ON
		prec.EarnType=hqet.EarnType /*LEFT OUTER JOIN
	 mnepto.EarnCodeMap  ecm ON
		prth.PRCo=ecm.PRCo
	AND CAST(prth.EarnCode AS VARCHAR(10))=CAST(ecm.EarnCode AS VARCHAR(10)) COLLATE Latin1_General_CI_AS */ JOIN	
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.HQCO hqco ON
		prth.PRCo=hqco.HQCo
WHERE
	hqco.udTESTCo <> 'Y' 
and	prth.udArea IS NOT NULL
--or	(hqet.Description IN ('Standard Earnings','Overtime Earnings','Other Earnings'))
OR  ( 
		prec.Description IN (SELECT DISTINCT Description  FROM [MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PREC WHERE EarnType IN (6,7)  )
	) 	
GROUP BY
	prth.PRCo
,	prth.Employee
,	preh.LastName + ', ' + preh.FirstName
,	COALESCE(CONVERT(CHAR(8),preh.HireDate, 112),0) 
,	COALESCE(CONVERT(CHAR(8),preh.RecentRehireDate,112),0)
,	COALESCE(CONVERT(CHAR(8),preh.TermDate, 112),0) 
,	COALESCE(CONVERT(CHAR(8),prth.PREndDate, 112),0) 
,	preh.ActiveYN 
,	hqet.Description
--,	ecm.ShortCode 
,   prth.Craft
,	prth.udArea 
ORDER BY 1,2

