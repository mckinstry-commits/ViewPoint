SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 3/20/2012
-- Description:	Genereate PM work orders for an agreement.
-- Modifications:
-- MB TK-20222 SM Agreement Work order Tax Source not defaulting from Agreement
-- MB TK-19731 PM Work Orders - Tracking WIP and Agreement Rates Flag modification.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGenerateAgreementWorkOrder]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@Service int,
	@ServiceDate bDate, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF (@Revision IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement Revision!'
		RETURN 1
	END
	
	IF (@Service IS NULL)
	BEGIN
		SET @msg = 'Missing SM Service!'
		RETURN 1
	END
	
	IF (@ServiceDate IS NULL)
	BEGIN
		SET @msg = 'Missing Scheduled Date!'
		RETURN 1
	END
	
	DECLARE @rcode int, @CustGroup bGroup, @Customer bCustomer, @ServiceSite varchar(20), 
		@ServiceCenter varchar(10), @DefaultServiceCenter varchar(10), @DefaultContactName varchar(61),
		@DefaultContactPhone varchar(20), @WorkOrder int, @Description varchar(60),
		@SchedulingOption tinyint, @SchedulingOptionDays tinyint, @ServicePriceMethod char(1), 
		@ServicePrice bDollar, @ServiceRateTemplate varchar(10), @BillToCustomer bCustomer, @Scope int,
		@CustomerPO varchar(30), @RateTemplate varchar(10), @CallType varchar(10), @TaxSource char(1), @TrackWIP bYN
	
	-- Retrieve Work Order and Work Order Scope Defaults
	SELECT
		@CustGroup = SMAgreement.CustGroup,
		@Customer = SMAgreement.Customer,
		@ServiceSite = SMAgreementService.ServiceSite,
		@ServiceCenter = SMAgreementService.ServiceCenter,
		@Description = SMAgreementService.[Description],
		@SchedulingOption = SMAgreementService.ScheOptDueType,
		@SchedulingOptionDays = SMAgreementService.ScheOptDays,
		@ServicePriceMethod = SMAgreementService.PricingMethod,
		@ServicePrice = SMAgreementService.PricingPrice,
		@ServiceRateTemplate = SMAgreementService.PricingRateTemplate,
		@BillToCustomer = COALESCE(SMServiceSite.BillToARCustomer, SMCustomer.BillToARCustomer, SMCustomer.Customer),
		@CustomerPO = SMAgreement.CustomerPO,
		@RateTemplate = ISNULL(SMServiceSite.RateTemplate, SMCustomer.RateTemplate),
		@CallType = SMAgreementService.CallType,
		@TaxSource = SMAgreementService.TaxSource
	FROM dbo.SMAgreementService
	INNER JOIN dbo.SMAgreement ON SMAgreement.SMCo = SMAgreementService.SMCo
		AND SMAgreement.Agreement = SMAgreementService.Agreement
		AND SMAgreement.Revision = SMAgreementService.Revision
	INNER JOIN dbo.SMServiceSite ON SMServiceSite.SMCo = SMAgreementService.SMCo 
		AND SMServiceSite.ServiceSite = SMAgreementService.ServiceSite
	INNER JOIN dbo.SMCustomer ON SMCustomer.SMCo = SMAgreementService.SMCo
		AND SMCustomer.CustGroup = SMAgreement.CustGroup
		AND SMCustomer.Customer = SMAgreement.Customer
	WHERE
		SMAgreementService.SMCo = @SMCo
		AND SMAgreementService.Agreement = @Agreement
		AND SMAgreementService.Revision = @Revision
		AND SMAgreementService.[Service] = @Service
		
	EXEC @rcode = dbo.vspSMServiceSiteVal @SMCo = @SMCo, @ServiceSite = @ServiceSite, @DefaultServiceCenter = @DefaultServiceCenter OUTPUT, @DefaultContactName = @DefaultContactName OUTPUT, @DefaultContactPhone = @DefaultContactPhone OUTPUT, @msg = @msg OUTPUT
	
	IF (@rcode <> 0)
	BEGIN
		RETURN @rcode 
	END
	
	SELECT @WorkOrder = ISNULL(MAX(SMWorkOrder.WorkOrder), 0) + 1, @msg = NULL FROM dbo.SMWorkOrder WHERE SMCo = @SMCo
	
	BEGIN TRY
		BEGIN TRANSACTION
		-- Create the Work Order
		INSERT INTO dbo.SMWorkOrder 
		(
			SMCo,
			WorkOrder,
			CustGroup,
			Customer,
			ServiceSite,
			ServiceCenter,
			EnteredDateTime,
			EnteredBy,
			ContactName,
			ContactPhone
		)
		SELECT
			@SMCo,
			@WorkOrder,
			@CustGroup,		-- From SM Agreement
			@Customer,		-- From SM Agreement
			@ServiceSite,	-- From SM Agreement Service
			ISNULL(@ServiceCenter, @DefaultServiceCenter),	-- From SM Agreement Service OR Service Site Validation
			GETDATE(),
			SUSER_NAME(),
			@DefaultContactName,	-- From Service Site Validation
			@DefaultContactPhone	-- From Service Site Validation

		SELECT @Scope = ISNULL(MAX(SMWorkOrderScope.Scope), 0) + 1 FROM dbo.SMWorkOrderScope 
		WHERE SMWorkOrderScope.SMCo = @SMCo AND SMWorkOrderScope.WorkOrder = @WorkOrder
		
		SELECT @TrackWIP = IsTrackingWIP FROM SMCallType
		WHERE SMCo = @SMCo AND CallType = @CallType
		
		-- Create Work Order Scope - default bill to, description, rate template
		INSERT INTO dbo.SMWorkOrderScope
		(
			SMCo,
			WorkOrder,
			Scope,
			Agreement,
			Revision,
			[Service],
			[Description],
			CallType,
			ServiceCenter,
			DueStartDate,
			DueEndDate,
			PriceMethod,
			UseAgreementRates,
			Price,
			CustGroup,
			BillToARCustomer,
			SaleLocation,
			IsTrackingWIP,
			CustomerPO,
			RateTemplate
		)
		SELECT
			@SMCo,
			@WorkOrder,
			@Scope,
			@Agreement,
			@Revision,
			@Service,
			@Description,	-- From SM Agreement Service
			@CallType,		-- From SM Agreement Service
			ISNULL(@ServiceCenter, @DefaultServiceCenter),	-- From SM Agreement Service OR Service Site Validation
			CASE WHEN @SchedulingOption = 3 THEN @ServiceDate ELSE NULL END,		-- Start Date for due within from Service
			CASE WHEN @SchedulingOption = 1 OR @SchedulingOption = 2 THEN @ServiceDate	-- End Date (either schedule date or modified value for due within from Service
				WHEN @SchedulingOption = 3 THEN DATEADD(d, @SchedulingOptionDays, @ServiceDate)
			END,
			CASE WHEN @ServicePriceMethod <> 'T' THEN 'C'		-- Translated Price Method from Service
				WHEN @ServicePrice IS NOT NULL THEN 'F'
				WHEN @ServiceRateTemplate IS NOT NULL THEN 'T'
			END,
			'N', -- Do not set Use Agreement Rates to True TK-19731.
			@ServicePrice,		-- From SM Agreement Service either NULL or value
			@CustGroup,
			@BillToCustomer,	-- From Service Site, or Customer
			--TaxSource is a Char(1) of either S - for service site or C for service center
			CASE WHEN @TaxSource = 'S' THEN 1 
				WHEN @TaxSource = 'C' THEN 0
			END,
			-- Default Is TrackingWIP to No as the work order does -- Not quite correct
			--WIP should be set to yes when call type assigned says so TK-19731 .
			@TrackWIP,
			@CustomerPO,
			CASE WHEN @ServicePriceMethod = 'T' AND @ServiceRateTemplate IS NOT NULL THEN @ServiceRateTemplate ELSE @RateTemplate END

		-- Create Work Order Scope Tasks
		INSERT INTO dbo.SMWorkOrderScopeTask
		(
			SMCo,
			WorkOrder,
			Scope,
			Task,
			SMStandardTask,
			Name,
			[Description],
			ServiceItem
		)
		SELECT @SMCo, @WorkOrder, @Scope, Task, SMStandardTask, Name, [Description], ServiceItem
		FROM SMAgreementServiceTask
		WHERE SMAgreementServiceTask.SMCo = @SMCo
		AND SMAgreementServiceTask.Agreement = @Agreement
		AND SMAgreementServiceTask.Revision = @Revision
		AND SMAgreementServiceTask.[Service] = @Service
		
		-- Mark the service as scheduled
		INSERT INTO dbo.SMAgreementServiceDate (SMCo, Agreement, Revision, [Service], ServiceDate, WorkOrder, Scope)
		VALUES (@SMCo, @Agreement, @Revision, @Service, @ServiceDate, @WorkOrder, @Scope)
		
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
		SELECT @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGenerateAgreementWorkOrder] TO [public]
GO
