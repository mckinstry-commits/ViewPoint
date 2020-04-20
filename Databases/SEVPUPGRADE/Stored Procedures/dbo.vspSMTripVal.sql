SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/13/10
-- Description:	SM trip validation
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTripVal]
	@SMCo bCompany, @WorkOrder int, @Trip int, @msg varchar(255) OUTPUT
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

	IF @Trip IS NULL
	BEGIN
		SET @msg = 'Missing SM Trip!'
		RETURN 1
	END

	SELECT @msg = [Description]
	FROM dbo.SMTrip
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Trip = @Trip
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Trip has not been setup.'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMTripVal] TO [public]
GO
