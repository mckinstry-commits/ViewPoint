SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 6/11/12
-- Description:	Get the information for terminating an agreement.
--				This is intended to be called only when loading the Terminate form.
-- Modified:	
--				9/17/12 JB - Modified Number of open and inactive work orders to include all for the same period.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementTerminateInfo]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
	@Description varchar(60) = NULL OUTPUT,
	@EffectiveDate bDate = NULL OUTPUT,
	@ExpirationDate bDate = NULL OUTPUT,
	@OutstandingQuoteExists bYN = NULL OUTPUT,
	@NumberOfOpenWorkOrders int = NULL OUTPUT,
	@NumberOfOpenInactiveWorkOrders int = NULL OUTPUT,
	@NumberOfPendingInvoices int = NULL OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	SELECT 
		@Description = [Description],
		@EffectiveDate = EffectiveDate,
		@ExpirationDate = ExpirationDate
	FROM dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
    
	IF (@@ROWCOUNT = 0)
	BEGIN		
		SELECT @NumberOfOpenWorkOrders=0, @NumberOfOpenInactiveWorkOrders=0, @NumberOfPendingInvoices=0
		RETURN 0
	END
	
	SET @OutstandingQuoteExists = CASE WHEN EXISTS(SELECT 1 FROM dbo.SMAgreementExtended WHERE SMCo = @SMCo AND Agreement = @Agreement AND PreviousRevision = @Revision AND [Status] = 0) THEN 'Y' ELSE 'N' END
	
	-- Retrieve the number of open but inactive (New) work orders
	SELECT @NumberOfOpenInactiveWorkOrders = COUNT(1)
	FROM
	(
		SELECT SMWorkOrderScope.WorkOrder
		FROM SMAgreementExtended CurrentRevision
			  INNER JOIN SMAgreementExtended ON CurrentRevision.SMCo = SMAgreementExtended.SMCo AND CurrentRevision.Agreement = SMAgreementExtended.Agreement AND CurrentRevision.OriginalRevision = SMAgreementExtended.OriginalRevision
			  INNER JOIN SMWorkOrderScope ON SMAgreementExtended.SMCo = SMWorkOrderScope.SMCo AND SMAgreementExtended.Agreement = SMWorkOrderScope.Agreement AND SMAgreementExtended.Revision = SMWorkOrderScope.Revision
			  INNER JOIN SMWorkOrderStatus ON SMWorkOrderScope.SMCo = SMWorkOrderStatus.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkOrderStatus.WorkOrder
		WHERE CurrentRevision.SMCo = @SMCo AND CurrentRevision.Agreement = @Agreement AND CurrentRevision.Revision = @Revision AND SMWorkOrderStatus.[Status] = 'New'
		GROUP BY SMWorkOrderScope.WorkOrder
	) AS WorkOrders
	
	-- Retrieve the number of open work orders
	SELECT @NumberOfOpenWorkOrders = COUNT(1)
	FROM
	(
		SELECT SMWorkOrderScope.WorkOrder
		FROM SMAgreementExtended CurrentRevision
			  INNER JOIN SMAgreementExtended ON CurrentRevision.SMCo = SMAgreementExtended.SMCo AND CurrentRevision.Agreement = SMAgreementExtended.Agreement AND CurrentRevision.OriginalRevision = SMAgreementExtended.OriginalRevision
			  INNER JOIN SMWorkOrderScope ON SMAgreementExtended.SMCo = SMWorkOrderScope.SMCo AND SMAgreementExtended.Agreement = SMWorkOrderScope.Agreement AND SMAgreementExtended.Revision = SMWorkOrderScope.Revision
			  INNER JOIN SMWorkOrderStatus ON SMWorkOrderScope.SMCo = SMWorkOrderStatus.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkOrderStatus.WorkOrder
		WHERE CurrentRevision.SMCo = @SMCo AND CurrentRevision.Agreement = @Agreement AND CurrentRevision.Revision = @Revision AND SMWorkOrderStatus.[Status] = 'Open'
		GROUP BY SMWorkOrderScope.WorkOrder
	) AS WorkOrders
	
	-- Retrieve the number of pending invoices
	SELECT @NumberOfPendingInvoices = COUNT(1) FROM dbo.SMAgreementBillingSchedule
	INNER JOIN dbo.SMInvoice ON SMInvoice.SMInvoiceID = SMAgreementBillingSchedule.SMInvoiceID
	WHERE SMAgreementBillingSchedule.SMCo = @SMCo AND SMAgreementBillingSchedule.Agreement = @Agreement
		AND SMAgreementBillingSchedule.Revision = @Revision AND SMInvoice.Invoiced = 0

    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementTerminateInfo] TO [public]
GO
