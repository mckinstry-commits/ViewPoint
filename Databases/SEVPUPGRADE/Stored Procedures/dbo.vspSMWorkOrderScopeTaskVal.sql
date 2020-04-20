SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/16/12
-- Description:	Validates a SM Agreement Service Task
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderScopeTaskVal]
	@SMCo bCompany, 
	@WorkOrder bigint, 
	@Scope int, 
	@Task int,
	@MustExist bYN, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON
	
	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @WorkOrder IS NULL THEN 'Missing Work Order!'
		WHEN @Scope IS NULL THEN 'Missing Scope!'
		WHEN @Task IS NULL THEN 'Missing Task!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	SELECT @msg = [Name]
	FROM dbo.SMWorkOrderScopeTask
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND Task = @Task
	
	IF @MustExist = 'Y'
	BEGIN
		IF @@rowcount = 0
		BEGIN
			SET @msg = 'Work Order Scope task has not been setup.'
			RETURN 1
		END
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopeTaskVal] TO [public]
GO
