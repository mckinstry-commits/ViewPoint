SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/7/2014
-- Description:	Return GLAcct for a given JCCo, Job, Phase, CostType
-- =============================================
CREATE FUNCTION [dbo].[mfnJCGLLookup] 
(
	-- Add the parameters for the function here
	@JCCo bCompany
	, @Job bJob
	, @Phase bPhase
	, @CostType bJCCType
	, @ValidChars INT
)
RETURNS VARCHAR(30)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result VARCHAR(20)

	-- Add the T-SQL statements to compute the return value here
	SELECT TOP 1 @Result = COALESCE(do.OpenWIPAcct,dm.OpenWIPAcct,'0000-000-0000')
	FROM JCCH ch
		INNER JOIN  dbo.JCJP jp	ON jp.JCCo = ch.JCCo AND jp.Job = ch.Job AND jp.Phase = ch.Phase
		INNER JOIN dbo.JCCI ci ON ci.JCCo = jp.JCCo AND ci.Contract = jp.Contract AND ci.Item = jp.Item
		INNER JOIN dbo.JCDC dm ON dm.JCCo = ci.JCCo AND dm.Department = ci.Department AND dm.CostType = ch.CostType
		LEFT OUTER JOIN dbo.JCDO do ON do.JCCo = dm.JCCo AND do.Department = dm.Department AND LEFT(do.Phase,@ValidChars) = LEFT(jp.Phase,@ValidChars)
	WHERE dm.JCCo = @JCCo AND jp.Job = @Job AND jp.Phase = @Phase AND (ch.CostType = @CostType OR @CostType = NULL)

	-- Return the result of the function
	RETURN @Result

END
GO
