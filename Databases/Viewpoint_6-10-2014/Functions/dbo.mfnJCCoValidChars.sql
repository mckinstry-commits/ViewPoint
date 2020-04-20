SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/7/2014
-- Description:	Return an INT for number of valid characters for a given JCCo.
-- =============================================
CREATE FUNCTION [dbo].[mfnJCCoValidChars] 
(
	-- Add the parameters for the function here
	@JCCo bCompany
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int

	-- Add the T-SQL statements to compute the return value here
	SELECT TOP 1 @Result = ValidPhaseChars FROM dbo.JCCO WHERE JCCo = @JCCo

	-- Return the result of the function
	RETURN @Result

END
GO
