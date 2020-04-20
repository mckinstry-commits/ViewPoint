SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 4/11/2013
-- Description:	Genereate work order from a quote
-- Modifications: SKA - 05/08/2013 - added SMEntity creation sections
-- Mod: MB - 5/13/13 - Removed create SM Entity for Work Order. Only scopes need entities.
--      EricV 6/6/13 - TFS-52285 Include the Notes column when copying Flat Price Revenue Split records from the Quote to the Work Order
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGenerateQuoteWorkOrder]
	@SMCo bCompany, 
	@Quote varchar(15), 
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
	
	IF (@Quote IS NULL)
	BEGIN
		SET @msg = 'Missing SM WO Quote!'
		RETURN 1
	END
	
	DECLARE @rcode int, @CustGroup bGroup, @Customer bCustomer, @ServiceSite varchar(20), 
		@ServiceCenter varchar(10), @DefaultServiceCenter varchar(10), @CustomerContactName varchar(60),
		@CustomerContactPhone varchar(20),  @DefaultContactName varchar(61),
		@DefaultContactPhone varchar(20), @RequestedBy varchar(50),
		@RequestedByPhone varchar(20), @RequestedByDate datetime, @WorkOrder int, @Description varchar(60),
		@SchedulingOption tinyint, @SchedulingOptionDays tinyint, @PriceMethod char(1), 
		@Price bDollar, @BillToCustomer bCustomer, @Scope int,
		@CustomerPO varchar(30), @RateTemplate varchar(10), @CallType varchar(10), @TaxSource char(1),
		@BillToARCustomer bCustomer

	-- Retrieve Work Order Header Defaults
	SELECT
		@CustGroup = vSMWorkOrderQuote.CustGroup,
		@Customer = vSMWorkOrderQuote.Customer,
		@ServiceSite = vSMWorkOrderQuote.ServiceSite,
		@ServiceCenter = vSMWorkOrderQuote.ServiceCenter,
		@Description = vSMWorkOrderQuote.[Description],
		@CustomerContactName = vSMWorkOrderQuote.CustomerContactName,
		@CustomerContactPhone = vSMWorkOrderQuote.CustomerContactPhone,
		@RequestedBy = vSMWorkOrderQuote.RequestedBy,
		@RequestedByPhone = vSMWorkOrderQuote.RequestedPhone,
		@RequestedByDate = vSMWorkOrderQuote.RequestedDate,
		@BillToARCustomer = COALESCE(vSMServiceSite.BillToARCustomer, vSMCustomer.BillToARCustomer, vSMCustomer.Customer)
	FROM dbo.vSMWorkOrderQuote
	INNER JOIN dbo.vSMServiceSite ON vSMServiceSite.SMCo = vSMWorkOrderQuote.SMCo 
		AND vSMServiceSite.ServiceSite = vSMWorkOrderQuote.ServiceSite
	INNER JOIN dbo.vSMCustomer ON vSMCustomer.SMCo = vSMWorkOrderQuote.SMCo
		AND vSMCustomer.CustGroup = vSMWorkOrderQuote.CustGroup
		AND vSMCustomer.Customer = vSMWorkOrderQuote.Customer
	WHERE
		vSMWorkOrderQuote.SMCo = @SMCo
		AND vSMWorkOrderQuote.WorkOrderQuote = @Quote
		
	EXEC @rcode = dbo.vspSMServiceSiteVal @SMCo = @SMCo, @ServiceSite = @ServiceSite, @DefaultServiceCenter = @DefaultServiceCenter OUTPUT, @DefaultContactName = @DefaultContactName OUTPUT, @DefaultContactPhone = @DefaultContactPhone OUTPUT, @msg = @msg OUTPUT
	
	IF (@rcode <> 0)
	BEGIN
		RETURN @rcode 
	END
	
	SELECT @WorkOrder = ISNULL(MAX(SMWorkOrder.WorkOrder), 0) + 1, @msg = NULL FROM dbo.SMWorkOrder WHERE SMCo = @SMCo
	
	BEGIN TRY
		BEGIN TRANSACTION

		--Approve the Quote	
		UPDATE vSMWorkOrderQuote 
			SET DateApproved=GETDATE()
			WHERE WorkOrderQuote = @Quote AND SMCo = @SMCo

		-- Create the Work Order
		INSERT INTO dbo.vSMWorkOrder 
		(
			SMCo,
			WorkOrder,
			CustGroup,
			Customer,
			ServiceSite,
			ServiceCenter,
			[Description],
			EnteredDateTime,
			EnteredBy,
			ContactName,
			ContactPhone,
			RequestedBy,
			RequestedByPhone,
			RequestedDate
		)
		SELECT
			@SMCo,
			@WorkOrder,
			@CustGroup,		
			@Customer,		
			@ServiceSite,	
			ISNULL(@ServiceCenter, @DefaultServiceCenter),	
			@Description,
			GETDATE(),
			SUSER_NAME(),
			@CustomerContactName,	
			@CustomerContactPhone,
			@RequestedBy,
			@RequestedByPhone,
			@RequestedByDate	
	
		-- Create Work Order Scopes
		INSERT INTO dbo.vSMWorkOrderScope
		(
			SMCo,
			WorkOrder,
			Scope,
			WorkScope,
			WorkOrderQuote,
			[Description],
			CallType,
			ServiceCenter,
			Division,
			DueStartDate,
			DueEndDate,
			PriceMethod,
			UseAgreementRates,
			Price,
			CustGroup,
			SaleLocation,
			IsTrackingWIP,
			CustomerPO,
			RateTemplate,
			NotToExceed,
			TaxType,
			TaxGroup,
			TaxCode,
			TaxRate,
			BillToARCustomer
		)
		SELECT
			vSMWorkOrderQuoteScope.SMCo,
			@WorkOrder,
			WorkOrderQuoteScope,
			WorkScope,
			@Quote,
			vSMWorkOrderQuoteScope.[Description],	
			vSMWorkOrderQuoteScope.CallType,	
			ISNULL(@ServiceCenter, @DefaultServiceCenter),	
			Division,
			DueStartDate,
			DueEndDate,
			PriceMethod,
			'N',
			Price,
			@CustGroup,
			--TaxSource is a Char(1) of either S - for service site or C for service center
			CASE WHEN TaxSource = 'S' THEN 1 
				WHEN TaxSource = 'C' THEN 0
			END,
			ISNULL(vSMCallType.IsTrackingWIP, 'N'),
			CustomerPO,
			RateTemplate,
			NotToExceed,
			TaxType,
			TaxGroup,
			TaxCode,
			TaxRate,
			@BillToARCustomer
		FROM dbo.vSMWorkOrderQuoteScope
		LEFT JOIN dbo.vSMCallType
			ON vSMCallType.SMCo = vSMWorkOrderQuoteScope.SMCo
			AND vSMCallType.CallType = vSMWorkOrderQuoteScope.CallType
		WHERE vSMWorkOrderQuoteScope.SMCo = @SMCo
			AND vSMWorkOrderQuoteScope.WorkOrderQuote = @Quote

		--Create the SM Entity record(s) for the new Work Order Scope(s)
		INSERT INTO dbo.vSMEntity 
		(
			Type, 
			SMCo, 
			EntitySeq, 
			WorkOrder,
			WorkOrderScope
		) 
		SELECT
			7, 
			@SMCo, 
			(select max(EntitySeq) from SMEntity) + ROW_NUMBER() OVER (ORDER BY qs.WorkOrderQuoteScope), 
			@WorkOrder, 
			qs.WorkOrderQuoteScope
		FROM dbo.vSMWorkOrderQuoteScope qs
		WHERE qs.SMCo = @SMCo
			AND qs.WorkOrderQuote = @Quote
		

		--Create new Flat Price Split record(s)
		INSERT INTO dbo.vSMFlatPriceRevenueSplit
		(
			SMCo,
			EntitySeq,
			Seq,
			CostTypeCategory,
			CostType,
			Amount,
			PricePercent,
			Taxable,
			Notes
		)
		SELECT
			fp.SMCo,
			ew.EntitySeq,
			Seq,
			CostTypeCategory,
			CostType,
			Amount,
			PricePercent,
			Taxable,
			fp.Notes
		FROM dbo.vSMFlatPriceRevenueSplit fp
		JOIN SMEntity eq ON
              eq.SMCo = fp.SMCo
              AND eq.EntitySeq = fp.EntitySeq
		JOIN dbo.vSMWorkOrderQuoteScope qs ON
              eq.SMCo = qs.SMCo
              AND eq.WorkOrderQuote = qs.WorkOrderQuote
              AND eq.WorkOrderQuoteScope = qs.WorkOrderQuoteScope
		JOIN dbo.vSMEntity ew ON
              ew.SMCo = qs.SMCo
              and ew.WorkOrderScope = qs.WorkOrderQuoteScope         
		WHERE ew.SMCo = @SMCo
		AND ew.WorkOrder = @WorkOrder
		AND eq.WorkOrderQuote = @Quote

		---- Create Work Order Scope Tasks
		INSERT INTO dbo.vSMRequiredTasks
		(
			SMCo,
			EntitySeq,
			Task,
			SMStandardTask,
			Name,
			[Description],
			ServiceSite,
			ServiceItem,
			Class,
			[Type],
			Manufacturer,
			Model,
			SerialNumber
		)
		SELECT
			rt.SMCo,
			ew.EntitySeq,
			Task,
			SMStandardTask,
			Name,
			rt.[Description],
			rt.ServiceSite,
			ServiceItem,
			Class,
			rt.[Type],
			Manufacturer,
			Model,
			SerialNumber
		FROM dbo.vSMRequiredTasks rt
		JOIN dbo.vSMEntity eq ON
              eq.SMCo = rt.SMCo
              AND eq.EntitySeq = rt.EntitySeq
		JOIN dbo.vSMWorkOrderQuoteScope qs ON
              eq.SMCo = qs.SMCo
              AND eq.WorkOrderQuote = qs.WorkOrderQuote
              AND eq.WorkOrderQuoteScope = qs.WorkOrderQuoteScope
		JOIN dbo.SMEntity ew ON
              ew.SMCo = qs.SMCo
              and ew.WorkOrderScope = qs.WorkOrderQuoteScope         
		WHERE ew.SMCo = @SMCo
		AND ew.WorkOrder = @WorkOrder
		AND eq.WorkOrderQuote = @Quote

		---- Mark the service as scheduled
		--INSERT INTO dbo.SMAgreementServiceDate (SMCo, Agreement, Revision, [Service], ServiceDate, WorkOrder, Scope)
		--VALUES (@SMCo, @Agreement, @Revision, @Service, @ServiceDate, @WorkOrder, @Scope)
		
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
GRANT EXECUTE ON  [dbo].[vspSMGenerateQuoteWorkOrder] TO [public]
GO
