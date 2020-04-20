
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   CREATE    procedure [dbo].[vspSMWorkCompletedCheckProvisional]
   /***********************************************************
    * Created:  Eric V 05/01/12
    * Modified: Eric V 06/05/12 Don't change provisional to new unless non-auto added work completed lines exist.
    *			Lane G 12/06/12 Added changes for Provisional Purchase Records so that when appropriate makes the 
	*							record New.
	*			EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
	*			EricV  06/25/13 TFS-4171 Price Rate and Price Total should be NULL when NonBillabe = 'Y'
    *
    * Check the provisional records aszsociated with a specific SM Work Order/Scope and if
    * any non-auto added work completed records have been added, then update the current
    * GL accounts and billable rate for each provisional record using the current Call Type
    * and Rate Template on the work order scope, and removing the provisional flag.
    * 
    *
    * Inputs:
    *   @smco   		SM Company
    *   @workorder  	SM Work Order
    *   @scope			SM Work Order Scope
    *
    * Output:
    *   @errmsg      error message if error occurs
    *
    * Return Value:
    *   0         success
    *   1         failure
    *****************************************************/
   
   	(@smco bCompany = null, @workorder bigint = null, @scope int = null, @errmsg varchar(255) = null output)
AS
   
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMCo=@smco AND WorkOrder=@workorder
		AND Scope=@scope AND Provisional=1)
		RETURN 0 -- No provisional records to update.

	IF NOT EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMCo=@smco AND WorkOrder=@workorder
		AND Scope=@scope AND AutoAdded=0)
		RETURN 0 -- No non-auto added work completed records exist.


	-- Update cost, price and GL accounts if all needed fields are present.
	DECLARE @SMWorkCompletedID bigint, @SMCo_upper bCompany, @WorkOrder int, @Scope int, @LineType tinyint, 
		@WorkCompleted int, @Date bDate, @CostType varchar(10), @DefaultCostAcct bGLAcct, 
		@DefaultRevenueAcct bGLAcct, @DefaultCostWIPAcct bGLAcct, @DefaultRevWIPAcct bGLAcct, 
		@DefaultTaxCode bTaxCode, @SMGLCo bCompany, @ServiceSite varchar(20),
		@msg varchar(255), @rcode int, @ProjCost bDollar,
		@ActualCost bDollar, @PriceRate bUnitCost, @PriceTotal bDollar,
		@Provisional bit, @CostQuantity bHrs, @StandardItem varchar(20), 
		@PRCo bCompany, @Technician varchar(15), @PayType varchar(10), @Craft bCraft, @Class bClass,
		@PriceQuantity bHrs, @TSLink bit, @TCLink bit, @Job bJob, @Agreement varchar(15),
		@Revision int,	@NonBillable bYN, @UseAgreementRates bYN,
		@MaterialGroup bGroup, @Material bMatl, @MaterialUM bUM,
		@Quantity bUnits, @PriceUM bUM, @PriceECM bECM
	
	DECLARE ProvisionalCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT SMWorkCompleted.SMWorkCompletedID, SMWorkCompleted.SMCo, SMWorkCompleted.WorkOrder, SMWorkCompleted.Scope, SMWorkCompleted.Type,
			SMWorkCompleted.WorkCompleted, SMWorkCompleted.[Date], SMWorkCompleted.SMCostType,
			SMWorkCompleted.PRCo, SMWorkCompleted.Technician, SMWorkCompleted.PayType, SMWorkCompleted.Craft,
			SMWorkCompleted.Class, SMWorkCompleted.CostQuantity, SMWorkCompleted.PriceQuantity,
			SMWorkCompleted.ProjCost,
			SMWorkCompleted.ActualCost, SMWorkCompleted.StandardItem,
			CASE WHEN SMMyTimesheetLink.SMWorkCompletedID IS NULL THEN 0 ELSE 1 END,
			CASE WHEN vSMBC.SMWorkCompletedID IS NULL THEN 0 ELSE 1 END,
			SMWorkOrder.Job, SMWorkCompleted.MatlGroup, SMWorkCompleted.Part, SMWorkCompleted.UM, SMWorkCompleted.Quantity, 
			SMWorkCompleted.PriceUM, SMWorkCompleted.PriceECM
		FROM SMWorkCompleted
		INNER JOIN SMWorkOrder ON SMWorkOrder.SMCo=SMWorkCompleted.SMCo
			AND SMWorkOrder.WorkOrder=SMWorkCompleted.WorkOrder
		LEFT JOIN SMMyTimesheetLink ON SMMyTimesheetLink.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
		LEFT JOIN vSMBC ON vSMBC.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
		WHERE SMWorkCompleted.SMCo=@smco AND SMWorkCompleted.WorkOrder=@workorder AND 
			SMWorkCompleted.Scope=@scope AND SMWorkCompleted.Provisional=1
		
	OPEN ProvisionalCursor
	FETCH NEXT FROM ProvisionalCursor INTO @SMWorkCompletedID, @SMCo_upper, @WorkOrder, @Scope, @LineType, @WorkCompleted, @Date, @CostType, @PRCo, @Technician, @PayType, @Craft, @Class, @CostQuantity, @PriceQuantity, @ProjCost, @ActualCost, @StandardItem, @TSLink, @TCLink, @Job, @MaterialGroup, @Material, @MaterialUM, @Quantity, @PriceUM, @PriceECM
	
	WHILE @@FETCH_STATUS = 0
	BEGIN	
	
		Select @Agreement = Agreement, @Revision = Revision, @NonBillable = NonBillable, @UseAgreementRates = UseAgreementRates
		FROM SMWorkCompleted 
		WHERE SMWorkCompletedID=@SMWorkCompletedID

		exec @rcode = vspSMWorkCompletedScopeVal
		@SMCo = @SMCo_upper, @WorkOrder = @WorkOrder, @Scope = @Scope, @LineType = @LineType, 
		@AllowProvisional='N',
		@SMCostType = @CostType,
		@DefaultCostAcct = @DefaultCostAcct OUTPUT,
		@DefaultRevenueAcct = @DefaultRevenueAcct OUTPUT,
		@DefaultCostWIPAcct = @DefaultCostWIPAcct OUTPUT,
		@DefaultRevWIPAcct = @DefaultRevWIPAcct OUTPUT,
		@DefaultTaxCode = @DefaultTaxCode OUTPUT, @ServiceSite = @ServiceSite OUTPUT,
		@SMGLCo = @SMGLCo OUTPUT, @msg=@msg OUTPUT
		
		IF(@rcode=0)
		BEGIN
			-- The scope now validates so remove the Provisional flag and update Cost, Price and GLAccounts.
			
			-- Lookup the price based on line type and rate templates
			IF (@LineType=2) -- Labor
			BEGIN
				-- Determine Cost and Price Rate.
				EXEC @rcode=vspSMLaborRateGet @SMCo=@SMCo_upper, @Technician=@Technician, @PayType=@PayType, @Job=@Job, @LaborCostRate=NULL, @JCCostType=NULL, @msg=@msg OUTPUT
				IF (@rcode=0)
				BEGIN
					-- Determine the Labor Price Rate
					IF @NonBillable='Y'
						SELECT @PriceRate = NULL 
					ELSE
						SELECT @PriceRate = Rate FROM dbo.vfSMRateLabor(@SMCo_upper, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @PRCo, @PayType, @Craft, @Class, @Technician)
				
					SELECT @Provisional=0, @PriceTotal=@PriceRate*@PriceQuantity
				END
			END
			ELSE IF(@LineType=3) -- Misc
			BEGIN
				EXEC @rcode = vspSMWorkCompletedStandardItemVal @SMCo=@SMCo_upper, @StandardItem=@StandardItem, @CostRate=NULL, @msg=@msg OUTPUT
				
				IF (@rcode=0)
				BEGIN
					-- Determine the Standard Item Price Rate
					IF @NonBillable='Y'
						SELECT @PriceRate = NULL 
					ELSE
						SELECT @PriceRate = BillableRate
						FROM dbo.vfSMGetStandardItemRate(@SMCo_upper, @WorkOrder, @Scope, @Date, @StandardItem, @Agreement, @Revision, @NonBillable, @UseAgreementRates)
				
					SELECT @Provisional=0, @PriceTotal=@PriceRate*@PriceQuantity
				END
			END
			ELSE IF(@LineType=5) -- Purchase
			BEGIN
				IF @NonBillable='Y'
					SELECT @Provisional=0, @PriceRate = NULL, @PriceTotal = NULL
				ELSE
					SELECT @Provisional=0, @PriceRate = PriceRate, @PriceTotal = PriceTotal
					FROM dbo.vfSMRatePurchase(@SMCo_upper, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @MaterialGroup, @Material, @MaterialUM, @Quantity, @ProjCost, @PriceUM, @PriceECM)
			END
			ELSE
			BEGIN
				-- Not Implemented.
				GOTO NEXT_RECORD
			END
		
			BEGIN TRY
				BEGIN TRAN	
	
				UPDATE vSMWorkCompleted SET Provisional=@Provisional
				WHERE SMWorkCompletedID = @SMWorkCompletedID
				
				UPDATE vSMWorkCompletedDetail 
					SET PriceRate=CASE WHEN vSMWorkCompleted.NonBillable='Y' then NULL ELSE @PriceRate END, 
					PriceTotal=CASE WHEN vSMWorkCompleted.NonBillable='Y' then NULL ELSE ISNULL(@PriceTotal,0) END, 
					GLCo=@SMGLCo, CostWIPAccount=@DefaultCostWIPAcct, RevenueWIPAccount=@DefaultRevWIPAcct,
					CostAccount=@DefaultCostAcct, RevenueAccount=@DefaultRevenueAcct	
				FROM vSMWorkCompletedDetail
				INNER JOIN vSMWorkCompleted ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				WHERE vSMWorkCompletedDetail.SMWorkCompletedID = @SMWorkCompletedID
					
				COMMIT TRAN
			END TRY
			BEGIN CATCH
				ROLLBACK TRAN
				CLOSE ProvisionalCursor
				DEALLOCATE ProvisionalCursor
				SET @errmsg = ERROR_MESSAGE()
				RETURN 1
			END CATCH
		END
NEXT_RECORD:	
		FETCH NEXT FROM ProvisionalCursor INTO @SMWorkCompletedID, @SMCo_upper, @WorkOrder, @Scope, @LineType, @WorkCompleted, @Date, @CostType, @PRCo, @Technician, @PayType, @Craft, @Class, @CostQuantity, @PriceQuantity, @ProjCost, @ActualCost, @StandardItem, @TSLink, @TCLink, @Job, @MaterialGroup, @Material, @MaterialUM, @Quantity, @PriceUM, @PriceECM
	END

	CLOSE ProvisionalCursor
	DEALLOCATE ProvisionalCursor

RETURN 0
GO

GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedCheckProvisional] TO [public]
GO
