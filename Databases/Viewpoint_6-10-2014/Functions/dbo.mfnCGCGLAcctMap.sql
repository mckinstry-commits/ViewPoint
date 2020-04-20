SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/7/2014
-- Description:	Return a GLAcct for a given GLAcct_Pt1 and a GLDept
-- =============================================
CREATE FUNCTION [dbo].[mfnCGCGLAcctMap] 
(
	-- Add the parameters for the function here
	@GLAcctPt1 VARCHAR(10)
	, @GLDept bDept 
)
RETURNS VARCHAR(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result VARCHAR(50)

	-- Add the T-SQL statements to compute the return value here
	
	SELECT @Result = a.newGLAcct--,pi.Instance,  dp.JCFixedRateGLAcct, a.oldGLAcct
	FROM /*[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll.*/dbo.udxrefGLAcct a
		INNER JOIN /*[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll.*/dbo.GLPI pi ON pi.PartNo=3 AND pi.Instance = SUBSTRING(a.newGLAcct,10,4)
		INNER JOIN /*[MCKTESTSQL04\VIEWPOINT].ViewpointPayroll.*/dbo.PRDP dp ON pi.Instance = RIGHT(dp.PRDept,4)
	WHERE pi.Instance = LEFT(@GLDept,4) AND LEFT(a.oldGLAcct,4) = @GLAcctPt1
	SELECT @Result = ISNULL(@Result,'0000-000-0000')
	-- Return the result of the function
	RETURN @Result

END
GO
