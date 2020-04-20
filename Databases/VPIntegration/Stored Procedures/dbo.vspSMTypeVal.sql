SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/23/11
-- Description:	Validation for SM Types
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMTypeVal]
	@SMCo AS bCompany, @Class AS varchar(15), @Type AS varchar(15), @msg AS varchar(255) OUTPUT
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
	
	IF (@Class IS NULL)
	BEGIN
		SET @msg = 'Missing SM Class!'
		RETURN 1
	END
	
	IF (@Type IS NULL)
	BEGIN
		SET @msg = 'Missing SM Type!'
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @IsActive = Active
	FROM dbo.SMType
	WHERE SMCo = @SMCo AND Class = @Class AND [Type] = @Type
    
    IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Class/Type has not been setup in SM Classification.'
		RETURN 1
    END
    
    IF (@IsActive <> 'Y')
    BEGIN
		SET @msg = 'Inactive Type - ' + ISNULL(@msg, '')
		RETURN 1
    END
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTypeVal] TO [public]
GO
