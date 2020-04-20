SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JG
-- Create date: 11/12/2010
-- Description:	Returns the next TempID for a company.
-- =============================================
CREATE FUNCTION [dbo].[vfJCJMGetNextTempProjID] 
(
	-- Add the parameters for the function here
	@CO bCompany
)
RETURNS bJob
AS
BEGIN
		-- Declare the return variable here
	DECLARE @nextJob bJob, @lastJob bJob, @PREFIX VARCHAR(4), @PRELen INT, @rcode INT
	DECLARE @Length INT
	
	SET @PREFIX = '---'
	SET @PRELen = LEN(@PREFIX)
	
	SELECT TOP 1 @Length=InputLength FROM DDDT
	WHERE Datatype = 'bJob' 

	SELECT TOP 1 @lastJob=Job FROM dbo.bJCJM
	WHERE Job LIKE '%' + @PREFIX + '%'
	AND JCCo = @CO
	ORDER BY Job DESC

	IF @lastJob IS NOT NULL
	BEGIN
		SET @nextJob = SUBSTRING(@lastJob, @PRELen + 1, LEN(@lastJob) - @PRELen) + 1
	END
	ELSE
	BEGIN
		SET @nextJob = '1'
	END
	
	SET @nextJob = @PREFIX + RIGHT('0000000000' + @nextJob, @Length-@PRELen)

	vspexit:
		RETURN @nextJob
	
END

GO
GRANT EXECUTE ON  [dbo].[vfJCJMGetNextTempProjID] TO [public]
GO
