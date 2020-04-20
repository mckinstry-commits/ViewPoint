SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 6/27/13
-- Description:	Validation for SM call types category
-- Modified: 
-- =============================================

CREATE PROCEDURE [dbo].[vspSMCallTypeCategoryColorVal]
	@SMCo AS bCompany, @CallTypeCategory AS varchar(15), @Color AS varchar(10), @msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @CallTypeCategory IS NULL
	BEGIN
		SET @msg = 'Missing SM Call Type Category!'
		RETURN 1
	END

	IF @Color IS NULL
	BEGIN
		SET @msg = 'Missing Color!'
		RETURN 1
	END
	
	IF EXISTS(SELECT 1 FROM dbo.SMCallTypeCategory WHERE SMCo = @SMCo AND Color = @Color AND CallTypeCategory <> @CallTypeCategory)
	BEGIN

		SET @msg = 'Category color Already used, choose a diffrent one!'
		RETURN 1

	END
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMCallTypeCategoryColorVal] TO [public]
GO
