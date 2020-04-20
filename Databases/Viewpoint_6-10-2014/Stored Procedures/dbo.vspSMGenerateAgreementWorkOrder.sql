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
-- MB US-43397 PM Work Orders - Copy split revenue lines on service
-- MB US-39989 Add Division to SMAgreementService
-- 05/21/13 EricV TFS-50951 - Use value of 'N' instead of 'C' for PriceMethod
-- 06/06/13 EricV TFS-52279 - Include the Taxable column when creating records in the vSMFlatPriceRevenueSplit table.
-- 06/10/13 ScottAlvey TFS 52507 - Corrected bug with Entity creation
-- 06/13/13 EricV TFS-4171 Only set the Price on the Work Order Scope when the Service is Time Of Service Flat Price.
-- 07/09/13 ScottAlvey TFS 55239 - bring FP agreement service taxes over from agreements to work order scope
-- 6/9/13 JVH TFS-55350 Fixed setting Use Agreement Rates so that the value is pushed down to the work completed.
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
	
	DECLARE @rcode int, @CustGroup bGroup, @Customer bCustomer, @ServiceSite varchar(20), @Division varchar(10),
		@ServiceCenter varchar(10), @DefaultServiceCenter varchar(10), @DefaultContactName varchar(61),
		@DefaultContactPhone varchar(20), @WorkOrder int, @Description varchar(60), @Entity int,
		@SchedulingOption tinyint, @SchedulingOptionDays tinyint, @ServicePriceMethod char(1), 
		@ServicePrice bDollar, @ServiceRateTemplate varchar(10), @BillToCustomer bCustomer, @Scope int,
		@CustomerPO varchar(30), @RateTemplate varchar(10), @CallType varchar(10), @TaxSource char(1), @TrackWIP bYN,
		@TaxGroup bGroup, @TaxCode bTaxCode, @TaxType int, @TaxRate bRate
	
	-- Retrieve Work Order and Work Order Scope Defaults
	SELECT
		@CustGroup = SMAgreement.CustGroup,
		@Customer = SMAgreement.Customer,
		@ServiceSite = SMAgreementService.ServiceSite,
		@Division = SMAgreementService.Division,
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
		@TaxSource = SMAgreementService.TaxSource,
		@TaxCode = (CASE WHEN SMAgreementService.PricingMethod = 'T'
						THEN (CASE WHEN SMAgreementService.TaxSource = 'C' THEN ISNULL(OCenter.TaxCode,DCenter.TaxCode) ELSE SMServiceSite.TaxCode END)
						ELSE NULL END),
		@TaxGroup = (CASE WHEN SMAgreementService.PricingMethod = 'T'
						THEN (CASE WHEN SMAgreementService.TaxSource = 'C' THEN ISNULL(OCenter.TaxGroup,DCenter.TaxGroup) ELSE SMServiceSite.TaxGroup END)
						ELSE NULL END)
	FROM dbo.SMAgreementService
	INNER JOIN dbo.SMAgreement ON SMAgreement.SMCo = SMAgreementService.SMCo
		AND SMAgreement.Agreement = SMAgreementService.Agreement
		AND SMAgreement.Revision = SMAgreementService.Revision
	INNER JOIN dbo.SMServiceSite ON SMServiceSite.SMCo = SMAgreementService.SMCo 
		AND SMServiceSite.ServiceSite = SMAgreementService.ServiceSite
	INNER JOIN dbo.SMServiceCenter DCenter on SMServiceSite.SMCo = DCenter.SMCo
		AND SMServiceSite.DefaultServiceCenter = DCenter.ServiceCenter
	LEFT OUTER JOIN dbo.SMServiceCenter OCenter on SMServiceSite.SMCo = OCenter.SMCo
		AND SMServiceSite.DefaultServiceCenter = OCenter.ServiceCenter
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

	SELECT @TaxType = (CASE WHEN ValueAdd = 'Y' THEN 2 ELSE 1 END) from HQTX WHERE TaxGroup = @TaxGroup and TaxCode = @TaxCode

	IF @ServicePriceMethod = 'T' and @TaxCode IS NOT NULL
	BEGIN
		EXEC @rcode = dbo.vspHQTaxCodeVal @TaxGroup, @TaxCode, null, @TaxType, @TaxRate OUTPUT

		IF (@rcode <> 0)
		BEGIN
			RETURN @rcode 
		END
	END
	
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
			Division,
			DueStartDate,
			DueEndDate,
			PriceMethod,
			UseAgreementRates,
			Price,
			CustGroup,
			BillToARCustomer,
			SaleLocation,
			TaxGroup,
			TaxCode,
			TaxType,
			TaxRate,
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
			@Division,
			CASE WHEN @SchedulingOption = 3 THEN @ServiceDate ELSE NULL END,		-- Start Date for due within from Service
			CASE WHEN @SchedulingOption = 1 OR @SchedulingOption = 2 THEN @ServiceDate	-- End Date (either schedule date or modified value for due within from Service
				WHEN @SchedulingOption = 3 THEN DATEADD(d, @SchedulingOptionDays, @ServiceDate)
			END,
			CASE WHEN @ServicePriceMethod <> 'T' THEN 'N'		-- Translated Price Method from Service
				WHEN @ServicePrice IS NOT NULL THEN 'F'
				WHEN @ServiceRateTemplate IS NOT NULL THEN 'T'
			END,
			CASE WHEN @ServicePriceMethod = 'T' THEN 'Y' ELSE 'N' END,
			CASE WHEN @ServicePriceMethod='T' THEN @ServicePrice ELSE NULL END,		-- From SM Agreement Service either NULL or value
			@CustGroup,
			@BillToCustomer,	-- From Service Site, or Customer
			--TaxSource is a Char(1) of either S - for service site or C for service center
			CASE WHEN @TaxSource = 'S' THEN 1 
				WHEN @TaxSource = 'C' THEN 0
			END,
			CASE WHEN @ServicePriceMethod = 'T' THEN @TaxGroup ELSE NULL END,
			CASE WHEN @ServicePriceMethod = 'T' THEN @TaxCode ELSE NULL END,
			CASE WHEN @ServicePriceMethod = 'T' THEN @TaxType ELSE NULL END,
			CASE WHEN @ServicePriceMethod = 'T' THEN @TaxRate ELSE NULL END,
			-- Default Is TrackingWIP to No as the work order does -- Not quite correct
			--WIP should be set to yes when call type assigned says so TK-19731 .
			@TrackWIP,
			@CustomerPO,
			CASE WHEN @ServicePriceMethod = 'T' AND @ServiceRateTemplate IS NOT NULL THEN @ServiceRateTemplate ELSE @RateTemplate END

		SET @Entity = (SELECT isnull(Max(EntitySeq),1) + 1 FROM vSMEntity)

		DECLARE @Type INT					
		SET @Type = 7

		INSERT INTO dbo.vSMEntity
			(
			[Type]
			,SMCo
			,EntitySeq
			,WorkOrder
			,WorkOrderScope
			)
		SELECT	
			@Type
			,@SMCo
			,@Entity
			,@WorkOrder
			,@Scope
		
		---- Create Work Order Scope Tasks
		INSERT INTO SMRequiredTasks
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
			SerialNumber,
			Notes
		)
		SELECT
			t.SMCo,
			@Entity,
			t.Task,
			t.SMStandardTask,
			t.Name,
			t.[Description],
			s.ServiceSite,
			t.ServiceItem,
			i.Class,
			i.[Type],
			i.Manufacturer,
			i.Model,
			i.SerialNumber,
			t.Notes
		FROM SMAgreementServiceTask t
		INNER JOIN SMAgreementService s on
			t.SMCo = s.SMCo
			AND t.Agreement = s.Agreement
			AND t.Revision = s.Revision
			AND t.[Service] = s.[Service]
		LEFT OUTER JOIN SMServiceItems i on
			s.SMCo = i.SMCo
			AND s.ServiceSite = i.ServiceSite
			AND t.ServiceItem = i.ServiceItem
		WHERE t.SMCo = @SMCo
		AND t.Agreement = @Agreement
		AND t.Revision = @Revision
		AND t.[Service] = @Service

		-- Mark the service as scheduled
		INSERT INTO dbo.SMAgreementServiceDate (SMCo, Agreement, Revision, [Service], ServiceDate, WorkOrder, Scope)
		VALUES (@SMCo, @Agreement, @Revision, @Service, @ServiceDate, @WorkOrder, @Scope)
					
		-- Copy revenue split records											
		INSERT INTO dbo.vSMFlatPriceRevenueSplit
		(
			 SMCo
			,EntitySeq
			,Seq
			,CostTypeCategory
			,CostType
			,Amount
			,PricePercent
			,Taxable
			,Notes
		)
		SELECT
			 vSMFlatPriceRevenueSplit.SMCo
			,NewRevEntity.EntitySeq
			,vSMFlatPriceRevenueSplit.Seq
			,vSMFlatPriceRevenueSplit.CostTypeCategory
			,vSMFlatPriceRevenueSplit.CostType
			,vSMFlatPriceRevenueSplit.Amount
			,vSMFlatPriceRevenueSplit.PricePercent
			,vSMFlatPriceRevenueSplit.Taxable
			,vSMFlatPriceRevenueSplit.Notes
		FROM
			vSMAgreementService INNER JOIN vSMEntity
			ON
				vSMAgreementService.SMCo = vSMEntity.SMCo AND vSMAgreementService.Agreement= vSMEntity.Agreement AND vSMAgreementService.Revision = vSMEntity.AgreementRevision AND vSMAgreementService.Service = vSMEntity.AgreementService
			INNER JOIN
				vSMFlatPriceRevenueSplit
			ON
				vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
			INNER JOIN
				vSMEntity NewRevEntity
			ON
				@SMCo = NewRevEntity.SMCo AND @WorkOrder = NewRevEntity.WorkOrder AND @Scope = NewRevEntity.WorkOrderScope
		WHERE
			vSMAgreementService.SMCo = @SMCo AND
			vSMAgreementService.Agreement = @Agreement AND
			vSMAgreementService.Revision = @Revision AND
			vSMAgreementService.Service = @Service
	
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
