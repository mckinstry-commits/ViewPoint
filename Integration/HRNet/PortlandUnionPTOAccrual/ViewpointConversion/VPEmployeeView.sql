--USE Viewpoint
GO

SELECT 
	prth.PRCo AS MCONO
,	prth.Employee AS MEENO
,	preh.LastName + ', ' + preh.FirstName AS MNM25
,	SUBSTRING(prdm.JCFixedRateGLAcct,10,4) AS MSDDP
--,	prth.Class AS MEECL
--,	'' AS MEETY
,	CASE
		WHEN CHARINDEX('.',prth.Class) <> 0 THEN LEFT(prth.Class,CHARINDEX('.',prth.Class)-1)  
		ELSE LEFT(prth.Class,3) 
	END AS MEECL
,	CASE
		WHEN CHARINDEX('.',prth.Class) <> 0 THEN RIGHT(prth.Class,LEN(prth.Class)-CHARINDEX('.',prth.Class))  
		ELSE RIGHT(prth.Class,LEN(prth.Class)-3) 
	END AS MEETY	
,	prth.Craft  AS MUNNO
,	prcm.Description AS QD15A
,	CASE preh.ActiveYN WHEN 'Y' THEN 'A' ELSE 'I' END  AS MSTAT
,	prgr.Description AS ExemptStatus
,	preh.udExempt
FROM 
	dbo.mvwPRTH prth JOIN
	dbo.bPREH preh ON
		prth.PRCo=preh.PRCo
	AND prth.PRGroup=preh.PRGroup
	AND prth.Employee=preh.Employee JOIN 
	PRCM prcm ON
		prth.PRCo=prcm.PRCo
	AND prth.Craft=prcm.Craft JOIN
	PRDP prdm ON
		prth.PRCo=prdm.PRCo
	AND prth.PRDept=prdm.PRDept JOIN
	PRGR prgr ON
		prth.PRCo=prgr.PRCo
	AND prth.PRGroup=prgr.PRGroup /* LEFT OUTER JOIN
	dbo.PEOPLE e ON
		CAST(prpmst.MEENO AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	*/

	SELECT * FROM PREHFullName
	
	
