USE [HRNET]
GO

/****** Object:  StoredProcedure [mnepto].[mspSyncPersonnel]    Script Date: 10/30/2014 08:40:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [mnepto].[mspSyncPersonnel]
(
	@EmployeeNumber  INT = NULL
)
as

/*
2014.10.30 - LWO - Altered to support conversion from CGC to Viewpoint

*/
-- INSERT MISSING
INSERT [mnepto].[Personnel]
(
	CompanyNumber	--int			NOT NULL 
,	EmployeeNumber	--int			NOT NULL
,	EmployeeName	--varchar(50)	NOT NULL
,	EmployeeDept	--varchar(10)	NOT NULL
,	EmployeeClass	--varchar(10)	NOT NULL
,	EmployeeType	--varchar(10)	NOT NULL
,	EmployeeUnion	--varchar(10)	NOT NULL
,	EmployeeUnionName
,	EmployeeStatus	--varchar(5)	NOT NULL
,	EmployeeExemptClassification	--varchar(20)	NOT NULL 
)
SELECT DISTINCT
	preh.PRCo AS MCONO
,	preh.Employee AS MEENO
,	preh.LastName + ', ' + preh.FirstName AS MNM25
,	SUBSTRING(prdm.JCFixedRateGLAcct,10,4) AS MSDDP
,	CASE
		WHEN CHARINDEX('.',preh.Class) <> 0 THEN LEFT(preh.Class,CHARINDEX('.',preh.Class)-1)  
		ELSE LEFT(preh.Class,3) 
	END AS MEECL
,	CASE
		WHEN CHARINDEX('.',preh.Class) <> 0 THEN RIGHT(preh.Class,LEN(preh.Class)-CHARINDEX('.',preh.Class))  
		ELSE RIGHT(preh.Class,LEN(preh.Class)-3) 
	END AS MEETY	
,	preh.Craft  AS MUNNO
,	prcm.Description AS QD15A
,	CASE preh.ActiveYN WHEN 'Y' THEN 'A' ELSE 'I' END  AS MSTAT
,	COALESCE(p.EXEMPTSTATUS,'Unknown')
FROM 
	--[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.mvwPRTH prth JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.bPREH preh JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PRCM prcm ON
		preh.PRCo=prcm.PRCo
	AND preh.Craft=prcm.Craft JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PRDP prdm ON   
		preh.PRCo=prdm.PRCo
	AND preh.PRDept=prdm.PRDept JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.HQCO hqco ON
		prdm.PRCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' join
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PRGR prgr ON
		preh.PRCo=prgr.PRCo
	AND preh.PRGroup=prgr.PRGroup LEFT OUTER JOIN
	dbo.PEOPLE e ON
		CAST(preh.Employee AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	
WHERE
(
(
	preh.ActiveYN='Y'
AND p.EXEMPTSTATUS = 'NonExempt' 
)
OR 	CAST(preh.PRCo AS VARCHAR(5)) + '.' + CAST(preh.Employee AS VARCHAR(10)) IN
	(
		SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
	)
)
AND CAST(preh.PRCo AS VARCHAR(5)) + '.' + CAST(preh.Employee AS VARCHAR(10)) NOT IN (
	SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.Personnel
)

-- UPDATE EXISTING
UPDATE mnepto.Personnel SET
	EmployeeName=t1.MNM25
,	EmployeeDept=t1.MSDDP
,	EmployeeClass=t1.MEECL
,	EmployeeType=t1.MEETY
,	EmployeeUnion=t1.MUNNO
,	EmployeeUnionName=t1.QD15A
,	EmployeeStatus=t1.MSTAT
,	EmployeeExemptClassification=t1.EXEMPTSTATUS
--SELECT * 
FROM 	
	mnepto.Personnel p JOIN
	(
SELECT DISTINCT
	prth.PRCo AS MCONO
,	prth.Employee AS MEENO
,	preh.LastName + ', ' + preh.FirstName AS MNM25
,	SUBSTRING(prdm.JCFixedRateGLAcct,10,4) AS MSDDP
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
,	COALESCE(p.EXEMPTSTATUS,'Unknown') AS EXEMPTSTATUS
,	CAST(prth.PRCo AS VARCHAR(5)) + '.' + CAST(prth.Employee AS varchar(10)) AS LogicalKey
FROM 
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.mvwPRTH prth JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.bPREH preh ON
		prth.PRCo=preh.PRCo
	AND prth.PRGroup=preh.PRGroup
	AND prth.Employee=preh.Employee JOIN 
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PRCM prcm ON
		prth.PRCo=prcm.PRCo
	AND prth.Craft=prcm.Craft JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PRDP prdm ON   
		prth.PRCo=prdm.PRCo
	AND prth.PRDept=prdm.PRDept JOIN
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.HQCO hqco ON
		prdm.PRCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' join
	[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PRGR prgr ON
		prth.PRCo=prgr.PRCo
	AND prth.PRGroup=prgr.PRGroup LEFT OUTER JOIN
	dbo.PEOPLE e ON
		CAST(prth.Employee AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	
WHERE
(
	preh.ActiveYN='Y'
AND p.EXEMPTSTATUS = 'NonExempt' 
)
	OR 	CAST(prth.PRCo AS VARCHAR(5)) + '.' + CAST(prth.Employee AS VARCHAR(10)) IN
		(
			SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
		)	
	)
	t1 ON p.LogicalKey=t1.LogicalKey
	WHERE
	(
		EmployeeName <> t1.MNM25 COLLATE Latin1_General_CI_AS
	OR	EmployeeDept <> t1.MSDDP COLLATE Latin1_General_CI_AS
	OR	EmployeeClass <> t1.MEECL COLLATE Latin1_General_CI_AS
	OR	EmployeeType <> t1.MEETY COLLATE Latin1_General_CI_AS
	OR	EmployeeUnion <> t1.MUNNO COLLATE Latin1_General_CI_AS
	OR	EmployeeStatus <> t1.MSTAT COLLATE Latin1_General_CI_AS
	OR	EmployeeExemptClassification <> t1.EXEMPTSTATUS COLLATE Latin1_General_CI_AS 
	)


GO

--exec [mnepto].[mspSyncPersonnel]

SELECT * FROM mnepto.Personnel