SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Eric Shafer
-- Create date: 
-- Description:	Function to provide new job number based on auto sequence rules.
-- =============================================
CREATE FUNCTION [dbo].[fnMckNewProjectID]
(	
@Company bCompany
	-- Add the parameters for the function here
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT @Company AS JCCo, CASE WHEN (MAX(CAST(SUBSTRING(TMP.Job, 1,6) AS INT))) <= 99999 THEN 100000 ELSE (MAX(CAST(SUBSTRING(TMP.Job,1,6)AS INT))) + 1 END AS NewProjectID
	--, MAX(TMP.Job)
	FROM 
	(SELECT JCCo AS JCCo, Job
	FROM JCJM a 
	INNER JOIN HQCO b ON b.HQCo = a.JCCo
	WHERE b.udTESTCo = (SELECT TOP 1 udTESTCo FROM HQCO WHERE HQCo = @Company)
	AND a.Job LIKE '%[0-9]-%'
	AND a.Job NOT LIKE '%[A-Z]%'
	AND a.Job NOT LIKE '%[a-z]%'
	UNION ALL
	SELECT JCCo, Job FROM [dbo].[mckPIFJCJobTemp]) AS TMP
)


GO
