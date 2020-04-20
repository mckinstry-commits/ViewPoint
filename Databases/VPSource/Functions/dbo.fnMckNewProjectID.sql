
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[fnMckNewProjectID]
(	
	-- Add the parameters for the function here
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	Select 
	0 as CompanyID,
	(MAX(CAST (SUBSTRING(Job,1, 6) AS int))) + 1 AS NewProjectID
	FROM JCJM a JOIN HQCO b on b.HQCo = a.JCCo
	
	WHERE b.udTESTCo = 'N' 
	AND a.Job LIKE '%[0-9]-%'
	AND a.Job NOT LIKE '%[A-Z]%'
	AND a.Job NOT LIKE '%[a-z]%'
)
GO
