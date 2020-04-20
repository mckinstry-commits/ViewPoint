SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 11/07/12
-- Description:	Dactivates an agreement with no activity,
--				returning it to quote status
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementDeactivation]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @errmsg varchar(max)

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @Agreement IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF @Revision  IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement Revision!'
		RETURN 1
	END
	
	IF EXISTS (select 1 from SMAgreementBillingScheduleExt where SMAgreementBillingScheduleExt.SMCo = @SMCo AND SMAgreementBillingScheduleExt.Agreement = @Agreement AND  SMAgreementBillingScheduleExt.Revision = @Revision AND SMAgreementBillingScheduleExt.SMInvoiceID IS NOT NULL)
	BEGIN
		SET @msg = 'Agreement has scheduled billing!'
		RETURN 1
	END
	
	IF EXISTS (select 1 from SMWorkOrderScope where SMWorkOrderScope.SMCo = @SMCo AND SMWorkOrderScope.Agreement = @Agreement AND SMWorkOrderScope.Revision = @Revision)
	BEGIN
		SET @msg = 'Agreement has work order!'
		RETURN 1
	END
	
	IF EXISTS (select 1 from SMAgreement where SMAgreement.SMCo = @SMCo AND SMAgreement.Agreement = @Agreement AND SMAgreement.[Status] = 0)
	BEGIN
		SET @msg = 'Agreement has open quote!'
		RETURN 1
	END
	 
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			
			BEGIN
				/* Deactivate the renewal */
				UPDATE SMAgreement
				SET DateActivated = NULL
				WHERE SMCo = @SMCo AND
					  Agreement = @Agreement AND
					  Revision = @Revision 
				
				IF @@rowcount <> 1
				BEGIN
					SET @msg = 'SM Agreement failed to deactivate!'
					ROLLBACK TRAN
					RETURN 1
				END
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			--If the error is due to a transaction count mismatch in vspSMAgreementDeleteNewWorkOrders
			--then it is more helpful to keep the error message from vspSMAgreementDeleteNewWorkOrders.
			IF ERROR_NUMBER() <> 266 SET @msg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			RETURN 1
		END CATCH
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementDeactivation] TO [public]
GO
