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

CREATE PROCEDURE [dbo].[vspSMCallTypeCategoryVal]
	@SMCo AS bCompany, @CallTypeCategory AS varchar(15), @msg AS varchar(255) OUTPUT
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
	
	SELECT @msg = [Description] 
	FROM dbo.SMCallTypeCategory
	WHERE SMCo = @SMCo AND CallTypeCategory = @CallTypeCategory
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMCallTypeCategoryVal] TO [public]
GO
