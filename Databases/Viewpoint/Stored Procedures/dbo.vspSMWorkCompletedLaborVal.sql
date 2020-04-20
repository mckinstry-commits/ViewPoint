SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 9/07/10
-- Description:	SM Work Order Misc Detail Validation
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedLaborVal]
	@SMCo bCompany,
	@WorkOrder int,
	@WorkCompleted int,
	@msg varchar(255) OUTPUT
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
	
	IF @WorkOrder IS NULL
	BEGIN
		SET @msg = 'Missing SM Work Order!'
		RETURN 1
	END

	SELECT @msg = ''
	FROM dbo.SMWorkCompleted
	WHERE [Type] = 2 AND SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Labor work completed has not been setup.'
		RETURN 1
	END
	
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedLaborVal] TO [public]
GO
