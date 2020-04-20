IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReportParams]'))
	DROP PROCEDURE [dbo].[mckrptProjectReportParams]
GO

-- ==================================================================================================================
-- Author:		Amit Mody
-- Create date: 10/08/2014
-- Change History
-- Date       Author            Description
-- ---------- ----------------- -------------------------------------------------------------------------------------
-- 1/29/2015  Amit Mody			Updated to use mckProjectReport
-- 2/19/2015  Amit Mody			Parameterized for revenue type of contract
-- 3/12/2015  Amit Mody			Supported All/Revenue/Non-Revenue types, trimmed description columns in return set
-- ==================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReportParams] 
	@returnField varchar(25) = 'CMPN' --'DEPT', 'CNTR', 'POCT'
,	@companies varchar(200) = ''
,	@depts varchar(200) = ''
,	@contracts varchar(200) = ''
,	@pocs varchar(200) = ''
,	@revtype tinyint = 0 --0=All, 1=Rev (A/C/M), 2=Non-rev (N)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX)

	SET @sql = N'SELECT'+ CASE @returnField	WHEN 'CMPN' THEN ' distinct pr.[JCCo], rtrim(ISNULL(hqco.Name, '''')) AS [JCCoName]'
											WHEN 'DEPT' THEN ' distinct pr.[GL Department] AS [Dept], rtrim(ISNULL(pr.[GL Department Name], '''')) AS [DeptName]'
											WHEN 'CNTR' THEN ' distinct pr.[Contract], rtrim(ISNULL(pr.[Contract Description], '''')) AS [ContractDesc]'
											WHEN 'POCT' THEN ' distinct pr.[Sales Person] AS [POC], rtrim(ISNULL(pr.[Sales Person], '''')) AS [POCName]'
						  END 
						+ ' FROM dbo.mckProjectReport pr'
						+ ' LEFT JOIN dbo.HQCO hqco'
						+ ' ON hqco.HQCo=pr.JCCo'
						+ ' WHERE'
						+ ' hqco.udTESTCo <> ''Y'' AND'
						+ CASE @revtype	WHEN 1 THEN ' pr.[Revenue Type] <> ''N'' AND'
										WHEN 2 THEN ' pr.[Revenue Type] = ''N'' AND'
										ELSE ''
						  END
						+ CASE @companies	WHEN '' THEN ' pr.JCCo IS NOT NULL AND'
											ELSE ' pr.JCCo IN (' + @companies	+ ') AND'
						  END
						+ CASE @contracts	WHEN '' THEN ' pr.Contract IS NOT NULL AND'
											ELSE ' pr.Contract IN (' + @contracts	+ ') AND'
						  END
						+ CASE @depts	WHEN '' THEN ' pr.[GL Department] IS NOT NULL'
										ELSE ' pr.[GL Department] IN (' + @depts	+ ')'
						  END
						+ CASE @pocs	WHEN '' THEN ''
										ELSE ' AND pr.[Sales Person] IN (' + @pocs	+ ')'
						  END
						+ ' ORDER BY 1'
						--+ CASE @returnField	WHEN 'CMPN' THEN ' pr.JCCo'
						--					WHEN 'DEPT' THEN ' pr.[GL Department],pr.[GL Department Name]'
						--					WHEN 'CNTR' THEN ' pr.Contract'
						--					WHEN 'POCT' THEN ' pr.[Sales Person]'
						--  END 

	--SELECT @sql
	EXEC sp_executesql @sql

END
GO

--Test Script
--*** CORE TEST CASES ***
--EXEC [mckrptProjectReportParams] 'CMPN'
--EXEC [mckrptProjectReportParams] 'DEPT', 1
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '''10054-'''
--EXEC [mckrptProjectReportParams] 'CNTR', 1
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '''0000'''

--EXEC [mckrptProjectReportParams] 'CMPN', '', '', '', '', 1
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '', '', 1
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '''100115-''', '', 1
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '', '', '', 1
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '''0000''', '', '', 1

--EXEC [mckrptProjectReportParams] 'CMPN', '', '', '', '', 2
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '', '', 2
--EXEC [mckrptProjectReportParams] 'DEPT', 1, '', '''100115-''', '', 2
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '', '', '', 2
--EXEC [mckrptProjectReportParams] 'CNTR', 1, '''0000''', '', '', 2

--*** OTHER TESTS ***
--EXEC [mckrptProjectReportParams]
--EXEC [mckrptProjectReportParams] 'DEPT'
--EXEC [mckrptProjectReportParams] 'CNTR'
--EXEC [mckrptProjectReportParams] 'POCT'
--EXEC [mckrptProjectReportParams] 'CMPN', '1,20,101' 
--EXEC [mckrptProjectReportParams] 'DEPT', '1', '''0000'',''0280'''
--EXEC [mckrptProjectReportParams] 'CNTR', '1', '', '''10000-'',''14382-'''
--EXEC [mckrptProjectReportParams] 'POCT', '1', '', '', '109'