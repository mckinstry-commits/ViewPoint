USE Viewpoint
GO

DECLARE @ROWTOTAL INT, @JCMPRows INT



--invalid PM Records - no matching PREH record.
SELECT JCMP.JCCo, JCMP.ProjectMgr, JCMP.Name--, ROW_NUMBER() OVER(ORDER BY JCMP.ProjectMgr)
FROM dbo.JCMP
	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
WHERE PREH.Employee IS NULL
	AND JCMP.JCCo < 100 --AND PREH.PRCo < 100
ORDER BY ProjectMgr DESC
--SELECT @ROWTOTAL=@@ROWCOUNT


--Records with incorrect match.
SELECT JCMP.JCCo AS [ProjectMgr JCCo], JCMP.ProjectMgr,JCMP.Name AS [ProjectMgr Name],PREH.PRCo AS [Employee PRCo], PREH.Employee, PREH.FirstName+' '+PREH.LastName AS [Full Employee Name] 
FROM dbo.JCMP
	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
WHERE PREH.Employee IS NOT NULL
	AND JCMP.JCCo < 100 
	AND LOWER(PREH.LastName) <> RIGHT((LOWER(JCMP.Name)),LEN(PREH.LastName))
ORDER BY ProjectMgr DESC
SELECT @ROWTOTAL=ISNULL(@ROWTOTAL,0)+@@ROWCOUNT

--Matching Records
SELECT JCMP.JCCo, JCMP.ProjectMgr,JCMP.Name,PREH.PRCo, PREH.Employee, PREH.FirstName+' '+PREH.LastName AS [Full PM Name] 
FROM dbo.JCMP
	LEFT OUTER JOIN dbo.PREH ON PREH.Employee=JCMP.ProjectMgr AND PREH.PRCo < 100 AND PREH.ActiveYN='Y'
WHERE PREH.Employee IS NOT NULL
	AND JCMP.JCCo < 100 AND PREH.PRCo < 100
	AND LOWER(PREH.LastName) = RIGHT((LOWER(JCMP.Name)),LEN(PREH.LastName))
	AND LOWER(JCMP.Name) = LOWER(PREH.FirstName+' '+PREH.LastName)
ORDER BY ProjectMgr DESC
SELECT @ROWTOTAL=@ROWTOTAL+@@ROWCOUNT

SELECT @JCMPRows=COUNT(*) FROM dbo.JCMP
WHERE JCCo <100 

SELECT @ROWTOTAL AS [MatchTotal Rows], @JCMPRows AS [Total PM Rows], @JCMPRows-@ROWTOTAL AS Difference


--SELECT COUNT(*)
--FROM dbo.PREH
--WHERE PRCo < 100