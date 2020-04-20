SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/8/2010
-- Description:	Validation proc for SM Service Center
-- =============================================
CREATE PROCEDURE [dbo].[vspSMServiceCenterVal]
	@SMCo AS int, @ServiceCenter AS varchar(10), @MustBeActive AS bit, @HasWorkCompleted bYN, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SMCo.'
		RETURN 1
	END
	
	IF @ServiceCenter IS NULL
	BEGIN
		SET @msg = 'Missing Service Center.'
		RETURN 1
	END
	
	IF @HasWorkCompleted = 'Y'
	BEGIN
		SET @msg = 'Cannot change Service Center when Work Completed records exists!'
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @IsActive = Active
    FROM dbo.SMServiceCenter
    WHERE SMCo = @SMCo AND ServiceCenter = @ServiceCenter
    
    IF @@rowcount = 0
    BEGIN
		SET @msg = 'Service Center has not been setup in SM Service Center.'
		RETURN 1
    END

	IF @IsActive <> 'Y'
    BEGIN
		SET @msg = ISNULL(@msg,'') + ' - Inactive Service Center.'
		IF @MustBeActive = 1
		BEGIN
			RETURN 1
		END
    END
    
    RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMServiceCenterVal] TO [public]
GO
