SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 06/011/13
-- Description:	Unapprove WO Quote
--
-- Modified:	
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderQuoteUnapproveValidate]
	@SMCo bCompany, 
	@WOQuote varchar(15), 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @Status varchar(16),
			@WorkOrder int,
			@rcode int,
			@TempMsg varchar(255)

	EXEC @rcode = vspSMWorkOrderQuoteVal @SMCo = @SMCo, @WorkOrderQuote = @WOQuote, @msg = @TempMsg
	IF @rcode <> 0
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Invalid Quote.'
		SET @msg = @msg + CHAR(10)
	END
	
	SELECT @Status =
	CASE 
		WHEN (SMWorkOrderQuote.DateCanceled IS NULL AND SMWorkOrderQuote.DateApproved IS NOT NULL) 
		THEN 'Approved' 
		WHEN (SMWorkOrderQuote.DateCanceled IS NOT NULL AND SMWorkOrderQuote.DateApproved IS NULL) 
		THEN 'Canceled' 
		ELSE 'Open' 
	END
	FROM SMWorkOrderQuote
	WHERE SMCo = @SMCo AND 
		  WorkOrderQuote = @WOQuote

	SELECT @WorkOrder = WOScope.WorkOrder
	FROM (
		SELECT TOP 1 *
		FROM dbo.SMWorkOrderScope
		WHERE SMWorkOrderScope.SMCo = @SMCo AND
			SMWorkOrderScope.WorkOrderQuote = @WOQuote
	) WOScope

	IF @Status <> 'Approved'
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Quote not in Approved status.'
		SET @msg = @msg + CHAR(10)
	END

	IF EXISTS (
		SELECT 1 FROM SMInvoiceDetail 
		where SMInvoiceDetail.SMCo = @SMCo
		AND SMInvoiceDetail.WorkOrder = @WorkOrder) 	
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Work Order has Billings.'
		SET @msg = @msg + CHAR(10)
	END

	IF EXISTS (
		SELECT 1 FROM SMWorkCompleted 
		where SMWorkCompleted.SMCo = @SMCo
			AND SMWorkCompleted.WorkOrder = @WorkOrder
			AND SMWorkCompleted.AutoAdded = 0)	
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Work Order has Work Completed.'
		SET @msg = @msg + CHAR(10)
	END

	IF EXISTS (
		SELECT 1 FROM SMWorkOrderScope 
		where SMWorkOrderScope.SMCo = @SMCo
			AND SMWorkOrderScope.WorkOrder = @WorkOrder 
			AND ISNULL(SMWorkOrderScope.WorkOrderQuote, '') <> @WOQuote) 
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Work Order has Non-Quote Scopes.'
		SET @msg = @msg + CHAR(10)
	END

	IF @msg IS NOT NULL
		RETURN 1

	BEGIN TRY
		BEGIN TRANSACTION
			
			DELETE FROM SMEntity
				WHERE SMCo = @SMCo
				AND WorkOrder = @WorkOrder

			DELETE FROM SMWorkCompleted
				WHERE SMCo = @SMCo
				AND WorkOrder = @WorkOrder
				AND AutoAdded = 1

			UPDATE SMWorkOrderScope
				SET WorkOrderQuote = NULL
				WHERE SMCo = @SMCo
				AND WorkOrder = @WorkOrder

			DELETE FROM SMWorkOrderScope
				WHERE SMCo = @SMCo
				AND WorkOrder = @WorkOrder

			DELETE FROM SMWorkOrder
				WHERE SMCo = @SMCo
				AND WorkOrder = @WorkOrder

			UPDATE SMWorkOrderQuote
				SET DateApproved = NULL
				WHERE SMCo = @SMCo AND 
				  WorkOrderQuote = @WOQuote

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SET @msg = ISNULL(@msg, '') + 'Unable to delete Work Order / Scopes.'
		SET @msg = @msg + CHAR(10)
		SET @msg = ISNULL(@msg, '') + ERROR_MESSAGE()
		SET @msg = @msg + CHAR(10)

		ROLLBACK TRANSACTION
	END CATCH

	IF @msg IS NOT NULL
		RETURN 1

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderQuoteUnapproveValidate] TO [public]
GO
