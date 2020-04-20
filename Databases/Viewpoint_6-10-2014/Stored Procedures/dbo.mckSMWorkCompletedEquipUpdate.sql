SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[mckSMWorkCompletedEquipUpdate] 
-- =============================================
-- Author:		Eric Shafer
-- Create date: 4/8/2014
-- Description:	Update the SMWorkCompletedEquipment record with changes
-- 
-- =============================================
	@SMCo bCompany, @WorkOrder int, @Scope INT--, @PayType varchar(10)
	, @SMCostType smallint=null, @Technician varchar(15), @UpdateFromPRTB bit=NULL,
	@Date smalldatetime, @Hours bHrs, @SMWorkCompletedID bigint, @IsBilled bit=NULL--, @Craft bCraft=NULL, @Class bClass=NULL, @Shift tinyint=NULL
	, @EMCo bCompany, @Equipment bEquip, @RevCode bRevCode
	,@TCPRCo bCompany = null, @TCPRGroup bGroup = null, @TCPREndDate smalldatetime = null, @TCPREmployee bEmployee = null,
	@TCPRPaySeq int = null, @TCPRPostSeq int = null, @TCPRPostDate smalldatetime = null,
	@SMJCCostType dbo.bJCCType=NULL, @SMPhaseGroup dbo.bGroup=NULL,
	@msg varchar(255) OUTPUT  
	
AS
BEGIN
	SET NOCOUNT ON;
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0
		
	DECLARE @rcode int, @TaxGroup bGroup, @TaxBasic bDollar, @GLCo bCompany, @CostAccount bGLAcct,
			@RevenueAccount bGLAcct, @CostWIPAccount bGLAcct, @RevenueWIPAccount bGLAcct, @CostRate numeric(16,5), @PriceRate numeric(16,5), 
			@TaxCode varchar(10), @LineType int, @TaxType int, @DefaultTaxType int, @TaxRate bRate, @ServiceSite varchar(20), 
			@SMGLCo bCompany, @WorkCompleted INT, @Agreement varchar(15),
			@Revision int,	@NonBillable bYN, @UseAgreementRates bYN, @Job bJob, @TaxBasis bDollar
			, @EMCategory bCat
	
	SELECT @LineType = 1
		
	/* Get the GL Account Number */
	exec @rcode = vspSMCoVal @SMCo=@SMCo, @GLCo=@GLCo OUTPUT, @TaxGroup=@TaxGroup OUTPUT, @msg = @msg OUTPUT
	IF (@rcode = 1)
		BEGIN
			goto error
		END
	
	/* Validate the Work Order Scope */
	exec @rcode = vspSMWorkOrderScopeVal @MustExist='Y',@SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope,
		@msg = @msg OUTPUT
	IF (@rcode = 1)
		BEGIN
			goto error
		END
		
	/* Get the Billed status if it is not already set */
	IF (@IsBilled IS NULL)
	BEGIN
		IF EXISTS
		(
			SELECT 1 
			FROM dbo.vSMWorkCompleted
				INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
			WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID
		)
			SET @IsBilled = 1
		ELSE
			SET @IsBilled = 0		
	END
	/* Get Scope related defaults */
	SELECT @WorkCompleted=WorkCompleted,
		@Agreement = @Agreement, @Revision = @Revision, @NonBillable=@NonBillable, @UseAgreementRates=@UseAgreementRates
		FROM SMWorkCompleted WHERE SMWorkCompletedID=@SMWorkCompletedID
	
	exec @rcode = vspSMWorkCompletedScopeVal @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope,
		@WorkCompleted=@WorkCompleted, @SMCostType=@SMCostType, @AllowProvisional = 'Y',
		@LineType=@LineType, @DefaultCostAcct=@CostAccount OUTPUT, @msg = @msg OUTPUT, 
		@DefaultRevenueAcct=@RevenueAccount OUTPUT, @DefaultCostWIPAcct=@CostWIPAccount OUTPUT,
		@DefaultRevWIPAcct=@RevenueWIPAccount OUTPUT, 
		@DefaultTaxType = @DefaultTaxType OUTPUT, @DefaultTaxCode=@TaxCode OUTPUT, 
		@ServiceSite=@ServiceSite OUTPUT, @SMGLCo=@SMGLCo OUTPUT, @Job = @Job OUTPUT
	/* We don't want to prevent entry of Timesheet so ignore error */
	
	IF (@IsBilled=0)
	BEGIN
		-- Clear out Tax related fields if this is related to a Job
		IF (@Job IS NOT NULL OR @NonBillable = 'Y')
		BEGIN
			SELECT @TaxCode = NULL, @TaxType = NULL, @TaxRate = NULL
		END
		
		-- Determine Tax Code if this is not related to a Job
		IF (@TaxCode IS NOT NULL)
		BEGIN
			-- Set Default Tax Type depending on Default Country
			SELECT @TaxType = @DefaultTaxType	
			
			/* Get the Tax Rate */
			exec @rcode = vspHQTaxCodeVal @taxgroup=@TaxGroup, @taxcode=@TaxCode, @compdate=@Date, @taxtype=@TaxType, @taxrate=@TaxRate OUTPUT, @msg = @msg OUTPUT
			IF (@rcode = 1)
			BEGIN
				goto error
			END
		END
	END
	
	/* Get CostRate and PriceRate */
	--exec @rcode = vspSMLaborRateGet @SMCo=@SMCo, @Technician=@Technician, @PayType=@PayType, @LaborCostRate=@CostRate OUTPUT, @JCCostType = null, @msg = @msg OUTPUT
	DECLARE @EMGroup bGroup
	SELECT @EMGroup = EMGroup
	FROM HQCO 
	WHERE HQCo = @EMCo
	SELECT @EMCategory = Category, @RevCode = RevenueCode
	FROM dbo.EMEM 
	WHERE EMCo = @EMCo AND Equipment = @Equipment

	SELECT @CostRate = dbo.vfEMRateEquipTempStdRate(@EMCo, @EMGroup, @Equipment,@RevCode)

	
	/* We don't want to prevent entry of Timesheet so ignore error */

	-- Determine the Equipment Price Rate
	IF EXISTS
	(
		SELECT 1
		FROM dbo.SMWorkOrder
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Job IS NOT NULL AND CostingMethod = 'Cost'
	)
	BEGIN
		SELECT @PriceRate = @CostRate
	END
	ELSE
	BEGIN
		IF (@NonBillable = 'Y')
			SELECT @PriceRate = NULL
		ELSE
			--SELECT @PriceRate = Rate FROM dbo.vfSMRateLabor(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @TCPRCo, @PayType, @Craft, @Class, @Technician)
			SELECT @PriceRate = PriceRate FROM dbo.vfSMRateEquipment(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @EMCo, @Equipment, @RevCode, @CostRate)
	END
	
	-- Determine Tax Basis
	SELECT @TaxBasis = CASE WHEN @Job IS NOT NULL OR @NonBillable='Y' THEN NULL ELSE @PriceRate * @Hours END		

	/* Update SMWorkCompleted with the new value for hours */
	--SELECT @SMWorkCompletedID=SMWorkCompletedID FROM SMWorkCompleted WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND WorkCompleted=@WorkCompleted AND Type=2
	IF (@IsBilled=0)
	BEGIN
IF (@PrintDebug=1) PRINT 'vspSMWorkCompletedEquipUpdate 1: Update SMWorkCompleted - IsBilled=0'
		UPDATE SMWorkCompleted SET Scope=@Scope, Technician=@Technician, TaxBasis=@TaxBasis, TaxType=@TaxType, TaxGroup=@TaxGroup, 
			TaxCode=@TaxCode, 
			TaxAmount=CASE WHEN @NonBillable='Y' THEN NULL ELSE @TaxRate*@PriceRate*@Hours END, 
			CostQuantity=@Hours, CostRate=@CostRate, ProjCost=@CostRate*@Hours, 
			TimeUnits=CASE WHEN @NonBillable='Y' THEN NULL ELSE @Hours END, 
			WorkUnits=CASE WHEN @NonBillable='Y' THEN NULL ELSE @Hours END, 
			PriceRate=CASE WHEN @NonBillable='Y' THEN NULL ELSE @PriceRate END, 
			PriceTotal=CASE WHEN @NonBillable='Y' THEN NULL ELSE @PriceRate*@Hours END, 
			RevCode = @RevCode, ActualCost = @Hours*@CostRate,
			Date=@Date--, PayType=@PayType
			, SMCostType=@SMCostType,
			GLCo=@SMGLCo, CostAccount=@CostAccount, RevenueAccount=@RevenueAccount, CostWIPAccount=@CostWIPAccount, 
			RevenueWIPAccount=@RevenueWIPAccount,-- Craft=@Craft, Class=@Class, Shift=@Shift,
			CostCo=@TCPRCo, PRCo=@TCPRCo, PRGroup=@TCPRGroup, PREndDate=@TCPREndDate, PREmployee=@TCPREmployee,
			PRPaySeq=@TCPRPaySeq, PRPostSeq=@TCPRPostSeq, PRPostDate=@TCPRPostDate
			, JCCostType=@SMJCCostType, PhaseGroup=@SMPhaseGroup
		WHERE SMWorkCompletedID = @SMWorkCompletedID
	END
	ELSE
	BEGIN
		/* Since the work completed record has already been billed the PriceQuantity, PriceRate, PriceTotal, 
		 TaxBasis, TaxType, TaxGroup, TaxCode and RevenueAccount cannot be changed. 
		 The vSMWorkCompletedLabor and vSMWorkCompletedDetail are updated directly so that any changes are
		 made to both the original record and the invoice session record. */
IF (@PrintDebug=1) PRINT 'vspSMWorkCompletedLaborUpdate 2: Update SMWorkCompleted - IsBilled=1'
IF (@PrintDebug=1) PRINT '  SMWorkCompletedID='+CONVERT(varchar, @SMWorkCompletedID)
		UPDATE vSMWorkCompletedDetail
			SET Technician=@Technician, GLCo=@SMGLCo, CostAccount=@CostAccount, CostWIPAccount=@CostWIPAccount, RevenueWIPAccount=@RevenueWIPAccount, Scope=@Scope
			WHERE SMWorkCompletedID = @SMWorkCompletedID
				
		--NEED TO REWRITE FOR EQUIPMENT

		--UPDATE vSMWorkCompletedEquipment
		--	SET CostQuantity=@Hours, CostRate=@CostRate, ProjCost=@CostRate*@Hours
		--	, PayType=@PayType,
		--	Craft=@Craft, Class=@Class, Shift=@Shift, SMCostType=@SMCostType,
		--	PRGroup=@TCPRGroup, PREndDate=@TCPREndDate, PREmployee=@TCPREmployee, 
		--	PRPaySeq=@TCPRPaySeq, PRPostSeq=@TCPRPostSeq, PRPostDate=@TCPRPostDate
		--	, Scope=@Scope, Date=@Date
		--	, JCCostType=@SMJCCostType, PhaseGroup=@SMPhaseGroup
		--	WHERE SMWorkCompletedID = @SMWorkCompletedID
		
		UPDATE vSMWorkCompleted
			SET CostCo=@TCPRCo, PRGroup=@TCPRGroup, PREndDate=@TCPREndDate, PREmployee=@TCPREmployee,
			PRPaySeq=@TCPRPaySeq, PRPostSeq=@TCPRPostSeq, PRPostDate=@TCPRPostDate
			WHERE SMWorkCompletedID = @SMWorkCompletedID
				
	END
   return
   error:
   	select @msg = isnull(@msg,'') + ' - cannot update SMWorkCompleted!'
   	RAISERROR(@msg, 11, -1);
   	rollback transaction
END
GO
