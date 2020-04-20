SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspSMWorkOrderVal]
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 08/13/10
-- Modified:    07/28/11 Eric V Added check of Provisional flag for IsBillable.
--				01/30/12 JG	- TK-00000 - Added the outputs JCCo, Job, and PhaseGroup returned from the Work Order.
--				02/02/12 MH - TK-12261 - Added PhaseGroup output param.  Was excluded from above change.
--				11/02/12 MB - TK-18934 - Added Coverage <> 'C' so Work completed covered by agreement will now show up as billable
--										 Or the billable button on SMWorkOrders will not be enabled when it shouldn't be.
-- Description:	SM Work Order validation
-- =============================================
	@SMCo bCompany, @WorkOrder int, @IsCancelledOK bYN, @status varchar(8) = NULL OUTPUT, 
	@isBillable bYN = NULL OUTPUT, @serviceSite varchar(20) = NULL OUTPUT, @WOStatus tinyint = NULL OUTPUT, 
	@HasWorkCompleted bYN = NULL OUTPUT, @HasTripThatArentOpen bYN = NULL OUTPUT, 
	@HasAssociatedPOs bYN = NULL OUTPUT, @HasServiceCenter bYN = NULL OUTPUT, 
	@JCCo dbo.bCompany = NULL OUTPUT, @Job dbo.bJob = NULL OUTPUT, @PhaseGroup bGroup = NULL OUTPUT,
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
	
	-- Set Work order info. Default status for new records to 'New'
	SELECT @status = 'New'
	SELECT @msg = [Description], @WOStatus = WOStatus, @status = [Status], @serviceSite = ServiceSite,
				@JCCo = JCCo, @Job = Job, @PhaseGroup = HQCO.PhaseGroup
	FROM dbo.SMWorkOrder
		INNER JOIN dbo.SMWorkOrderStatus ON SMWorkOrder.SMCo = SMWorkOrderStatus.SMCo
			AND SMWorkOrder.WorkOrder = SMWorkOrderStatus.WorkOrder
		LEFT JOIN dbo.HQCO on dbo.SMWorkOrder.JCCo = dbo.HQCO.HQCo
	WHERE SMWorkOrder.SMCo = @SMCo AND SMWorkOrder.WorkOrder = @WorkOrder

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Work Order has not been setup.'
		RETURN 1
	END
	
	IF @WOStatus = 2 AND @IsCancelledOK = 'N'
	BEGIN
		SET @msg = 'Cannot use canceled Work Order.'
		RETURN 1
	END

	SET @isBillable = 'N'	
	
	IF EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND SMInvoiceID IS NULL AND Provisional=0 AND (Coverage IS NULL OR Coverage <> 'C') AND NOT NonBillable = 'Y')
	BEGIN
		SET @isBillable = 'Y'
	END
	
	SET @HasWorkCompleted = 'N'
	
	-- Check for existance of Work Completed records
	IF EXISTS (SELECT 1 FROM dbo.SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Provisional=0)
	BEGIN
		SET @HasWorkCompleted = 'Y'
	END

	SET @HasTripThatArentOpen = 'N'

	-- Check for existance of Work Completed records
	IF EXISTS (SELECT 1 FROM dbo.SMTrip WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND [Status] > 0)
	BEGIN
		SET @HasTripThatArentOpen = 'Y'
	END
	
	SET @HasAssociatedPOs = 'N'
	
	-- Check for existance of associated POs
	IF EXISTS (SELECT 1 FROM dbo.SMPurchaseOrderList WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder)
	BEGIN
		SET @HasAssociatedPOs = 'Y'
	END
	
	--Service Center exist in WO?
	IF EXISTS (SELECT 1 FROM dbo.SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder and ServiceCenter is null)
	BEGIN
		SET @HasServiceCenter = 'N'
	END

    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderVal] TO [public]
GO
