IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptOcipCcip]'))
	DROP PROCEDURE [dbo].[mckrptOcipCcip]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 1/16/2015 Amit Mody			Authored
**
***********************************************************************************************************/

CREATE PROCEDURE [dbo].[mckrptOcipCcip]
	@PRMonth	smalldatetime = null,
	@PRCo		tinyint = NULL,
	@InsState	varchar(4) = NULL,
	@InsCode	varchar(10) = NULL,
	@Job		varchar(10) = NULL
AS
BEGIN
	SELECT	PRCo AS [PR Company]
	,		CompanyName AS [PR Company Name]
	,		Employee
	,		FirstName AS [First Name]
	,		LastName AS [Last Name]
	,		PREndDate AS [Payroll End Date]
	,		Hours
	,		Rate
	,		TimeCardEarn AS [Timecard Earnings]
	,		STE AS [Straight-time Earnings]
	,		VarSTE AS [Variable Earnings]
	,		AddonEarn AS [Add-on Earnings]
	,		LiabAmt AS [Liability Amount]
	,		JCCo AS [JC Company]
	,		[JCCo Name] AS [JC Company Name]
	,		JobDescription AS [Job Description]
	,		Phase
	,		InsState AS [Insurance State]
	,		InsCode AS [Insurance Code]
	,		InsDescription AS [Insurance Description]
	,		LiabCode AS [Liability Code]
	,		DLType AS [DL Type]
	,		DLDescription AS [DL Description]
	,		Method
	FROM	mvwPRLiability
	WHERE	PREndDate <= getdate()
	AND		(@PRCo IS NULL OR PRCo = @PRCo)
	AND		(@InsState IS NULL OR InsState = @InsState)
	AND		(@InsCode IS NULL OR InsCode = @InsCode)
	AND		(@Job IS NULL OR Job = @Job)
	ORDER BY PRCo, JCCo, Job, InsState, InsCode, LiabCode, Employee, Phase
END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[mckrptOcipCcip] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC dbo.mckrptOcipCcip
--EXEC dbo.mckrptOcipCcip '12/1/2014',1,'OR','5183',null