SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- =============================================
-- Author:		Eric Vaterluas
-- Create date: 6/18/12
-- Description:	Delete an Agreement Service Date
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementServiceDateDelete]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@Service int, 
	@WorkOrder int,
	@Scope int,
	@SkipFlag bYN = 'N',
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON
	
	DECLARE @ServiceDate smalldatetime
	
	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @Agreement IS NULL THEN 'Missing Agreement!'
		WHEN @Revision IS NULL THEN 'Missing Revision!'
		WHEN @Service IS NULL THEN 'Missing Seq!'
		WHEN @WorkOrder IS NULL THEN 'Missing SM Work Order!'
		WHEN @Scope IS NULL THEN 'Missing SM Work Order Scope!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	SELECT @ServiceDate = ServiceDate
	FROM dbo.SMAgreementServiceDate
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Service] = @Service AND WorkOrder = @WorkOrder AND @Scope=Scope

	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Agreement service date has not been found.'
		RETURN 1
    END

	BEGIN TRY
		IF(@SkipFlag = 'N')
		BEGIN
			DELETE SMAgreementServiceDate WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Service] = @Service AND ServiceDate = @ServiceDate
		END
		ELSE
		BEGIN
			-- Remove the Work Order Scope from the Agreement Service Date record so a work order will not be recreated for that date.
			UPDATE SMAgreementServiceDate SET WorkOrder=NULL, Scope=NULL WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Service] = @Service AND ServiceDate = @ServiceDate
		END
	END TRY
	BEGIN CATCH
		SELECT @msg = 'Unable to delete Agreement Service Date. ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	/* Delete Work Order Scope Tasks since they cannot be deleted manually. */
	BEGIN TRY
		DELETE SMWorkOrderScopeTask WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope
	END TRY
	BEGIN CATCH
		SELECT @msg = 'Unable to delete Work Order Scope Tasks. ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
	

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementServiceDateDelete] TO [public]
GO
