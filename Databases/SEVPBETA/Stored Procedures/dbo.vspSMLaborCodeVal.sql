SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMLaborCodeVal]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/7/11
-- Description:	Validation for SM Labor Codes
-- Modified:	JG 01/20/2012 - TK-11897 - Returning the JC Cost Type
-- =============================================
	@SMCo AS bCompany, 
	@LaborCode AS varchar(15), 
	@Job dbo.bJob = NULL,
	@PayType VARCHAR(10) = NULL,
	@SMCostType SMALLINT = NULL,
	@Description AS varchar(255) OUTPUT,
	@JCCostType AS dbo.bJCCType OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@LaborCode IS NULL)
	BEGIN
		SET @msg = 'Missing SM Labor Code!'
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @Description = [Description], @IsActive = Active
	FROM dbo.SMLaborCode
	WHERE SMCo = @SMCo AND LaborCode = @LaborCode
    
    IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Labor code has not been setup in SM Labor Code.'
		RETURN 1
    END
    
    IF (@IsActive <> 'Y')
    BEGIN
		SET @msg = 'Inactive labor code.'
		RETURN 1
    END
    
    --TK-11897
    DECLARE @rcode TINYINT
    SET @rcode = 0
    
    EXEC	@rcode = vspSMJCCostTypeDefaultVal 
			@SMCo = @SMCo
			, @Job = @Job
			, @LineType = 2 -- Labor
			, @LaborCode = @LaborCode
			, @PayType = @PayType
			, @SMCostType = @SMCostType
			, @JCCostType = @JCCostType OUTPUT
			, @msg = @msg OUTPUT
    
    RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspSMLaborCodeVal] TO [public]
GO
