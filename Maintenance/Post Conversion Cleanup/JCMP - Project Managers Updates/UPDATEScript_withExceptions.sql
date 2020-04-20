USE Viewpoint
GO

--UPDATE MATCHES WITH FULL LINK AND NO NAME MATCH ISSUES
UPDATE dbo.JCMP
SET udPRCo = PREH.PRCo, udEmployee = ProjectMgr
	FROM dbo.JCMP 
	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
WHERE PREH.Employee IS NOT NULL
	AND JCMP.JCCo =222 AND PREH.PRCo < 100
	AND LOWER(PREH.LastName) = RIGHT((LOWER(JCMP.Name)),LEN(PREH.LastName))



----Records with match but incorrect last name match.
--SELECT JCMP.JCCo AS [ProjectMgr JCCo], JCMP.ProjectMgr,JCMP.Name AS [ProjectMgr Name],PREH.PRCo AS [Employee PRCo], PREH.Employee, PREH.FirstName+' '+PREH.LastName AS [Full Employee Name] 
--FROM dbo.JCMP
--	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
--WHERE PREH.Employee IS NOT NULL
--	AND JCMP.JCCo < 100 
--	AND LOWER(PREH.LastName) <> RIGHT((LOWER(JCMP.Name)),LEN(PREH.LastName))
--ORDER BY ProjectMgr DESC


----invalid PM Records - no matching PREH record.
--SELECT JCMP.JCCo, JCMP.ProjectMgr, JCMP.Name--, ROW_NUMBER() OVER(ORDER BY JCMP.ProjectMgr)
--FROM dbo.JCMP
--	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
--WHERE PREH.Employee IS NULL
--	AND JCMP.JCCo < 100 --AND PREH.PRCo < 100
--ORDER BY ProjectMgr DESC