SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[mckSMWorkCompletedEquipCreate]   
-- =============================================
-- Author:		Eric Shafer
-- Create date: 4/4/2014
-- Description:	Create SMWorkCompleted record for Equipment from Payroll time entry.
-- Modifications: 
-- =============================================
 @SMCo bCompany, @WorkOrder int, @Scope int, @SMCostType smallint=null, @Date smalldatetime, @Technician varchar(15), @Hours bHrs,   
 @WorkCompleted int, @SMJCCostType dbo.bJCCType = NULL, @SMPhaseGroup dbo.bGroup,
 @SMWorkCompletedID int OUTPUT, @TCPRCo bCompany, @TCPREmployee bEmployee = NULL --, @OldPostSeq INT
 ,@msg varchar(255) = NULL OUTPUT  
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @TaxGroup bGroup, @TaxBasis bDollar, @GLCo bCompany, @CostAccount bGLAcct, @RevenueAccount bGLAcct, @RevenueWIPAccount bGLAcct,
			@CostWIPAccount bGLAcct, @CostRate numeric(16,5), @PriceRate numeric(16,5), @NextSeq int, 
			@TaxCode varchar(10), @LineType int, @TaxType int, @DefaultTaxType int, @TaxRate bRate,
			@ServiceSite varchar(20), @rcode int, @PRCo bCompany, @SMGLCo bCompany,
			@Provisional BIT, @Agreement varchar(15), @Revision int, 
			@NonBillable bYN, @UseAgreementRates bYN, @Job bJob, @RevCode bRevCode
			
			
	SET @LineType = 1

	/* Get the GL Account Number */
	EXEC @rcode = vspSMCoVal @SMCo=@SMCo, @GLCo=@GLCo OUTPUT, @PRCo=@PRCo OUTPUT, @TaxGroup=@TaxGroup OUTPUT, @msg=@msg OUTPUT
	IF (@rcode = 1)
	BEGIN
		goto error			
	END
	
	/* Validate Workorder Scope and get Scope related defaults */
	EXEC @rcode = vspSMWorkCompletedScopeVal @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted=@WorkCompleted,
		@LineType=@LineType, @AllowProvisional='Y', @SMCostType=@SMCostType, @DefaultCostAcct=@CostAccount OUTPUT, 
		@SMGLCo=@SMGLCo OUTPUT, @DefaultRevenueAcct=@RevenueAccount OUTPUT,
		@DefaultCostWIPAcct=@CostWIPAccount OUTPUT, @DefaultRevWIPAcct=@RevenueWIPAccount OUTPUT,
		@DefaultTaxType = @DefaultTaxType OUTPUT, @DefaultTaxCode=@TaxCode OUTPUT, 
		@ServiceSite=@ServiceSite OUTPUT, @Provisional=@Provisional OUTPUT, 
		@Agreement=@Agreement OUTPUT, @Revision=@Revision OUTPUT, @NonBillable=@NonBillable OUTPUT, @UseAgreementRates=@UseAgreementRates OUTPUT, 
		@Job = @Job OUTPUT, @msg=@msg OUTPUT
	IF (@rcode=1)
	BEGIN
		GOTO error
	END
	
	-- Clear out Tax related fields if this is related to a Job
	IF (@Job IS NOT NULL OR @NonBillable = 'Y')
	BEGIN
		SELECT @TaxCode = NULL, @TaxType = NULL, @TaxRate = NULL
	END
	
	IF (@TaxCode IS NOT NULL)
	BEGIN
		-- Set Default Tax Type depending on Default Country
		SELECT @TaxType = @DefaultTaxType

		/* Get the Tax Rate */
		EXEC @rcode = vspHQTaxCodeVal @taxgroup=@TaxGroup, @taxcode=@TaxCode, @compdate=@Date, @taxtype=@TaxType, @taxrate=@TaxRate OUTPUT, @msg=@msg OUTPUT
		IF (@rcode = 1)
		BEGIN
			goto error
		END
	END
	
	
	
	/* NEEDS UPDATE TO EQUIPMENT RATE GET */
	--STILL NEED TO GET Cost Rate for Equipment to determine Price Rate.
	DECLARE @EMCo bCompany, @Equipment bEquip, @PostWorkUnits bYN, @Basis CHAR(1), @TimeUM bUM, @WorkUM bUM, @EMGroup bGroup
		, @PriceTotal bDollar
	IF (SELECT COUNT(*) FROM dbo.EMEM WHERE PRCo=@PRCo AND Operator=@TCPREmployee) <> 1
	BEGIN
	SET @rcode=1
	SET @msg='More than one matching equipment record.  This is not allowed.'
	GOTO error
	END

	SELECT @EMCo=EMCo, @Equipment=Equipment, @EMGroup = EMGroup, @RevCode = RevenueCode
		FROM dbo.EMEM 
		WHERE PRCo = @PRCo AND Operator = @TCPREmployee
	
	--SELECT * FROM dbo.vfEMEquipmentRevCodeSetup(101,1,101,1)
	SELECT @Basis = Basis, @CostRate = Rate, @PostWorkUnits = PostWorkUnits, @TimeUM = TimeUM, @WorkUM = WorkUM
		FROM dbo.vfEMEquipmentRevCodeSetup(@EMCo, @Equipment, @EMGroup, @RevCode)
		WHERE CategorySetupExists = 'Y' OR EquipmentSetupExists = 'Y'
	
	SELECT @PriceRate = PriceRate FROM dbo.vfSMRateEquipment(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @EMCo, @Equipment, @RevCode, @CostRate)
	SET @PriceTotal = ISNULL(@PriceRate,0) * ISNULL(@Hours,0)

	
	-- Determine Tax Basis
	SELECT @TaxBasis = CASE WHEN @Job IS NOT NULL OR @NonBillable = 'Y' THEN NULL ELSE @PriceTotal END
	
	/* Insert records in SMWorkCompleted */
	BEGIN TRY
		--INSERT TO SMWorkCompleted Equipment Record
		INSERT INTO dbo.SMWorkCompleted(
			SMCo, WorkOrder, Type, WorkCompleted, Scope, Date, NonBillable, MonthToPostCost, Technician, SMCostType
			, EMCo, EMGroup, Equipment, RevCode, ServiceSite  
			, TimeUnits, WorkUnits, NoCharge
			, TaxGroup, TaxType, TaxCode, TaxBasis, TaxAmount, Notes, GLCo, CostAccount, CostWIPAccount
			, RevenueAccount, RevenueWIPAccount, CostRate
			, PriceRate
			, PriceTotal
			, PhaseGroup
			, ActualCost, UseAgreementRates, Agreement--, PRPostSeq
			)
		SELECT @SMCo, @WorkOrder, @LineType, @WorkCompleted, @Scope, @Date, @NonBillable, dbo.vfFirstDayOfMonth(@Date), @Technician, @SMCostType
			, @EMCo, @EMGroup, @Equipment, @RevCode, @ServiceSite
			, @Hours, @Hours, 'N'
			, @TaxGroup, @TaxType, @TaxCode, @TaxBasis, @TaxBasis * @TaxRate, 'Loaded from PRTH trigger.', @GLCo, @CostAccount, @CostWIPAccount
			, @RevenueAccount, @RevenueWIPAccount, @CostRate
			, CASE WHEN @NonBillable = 'Y'THEN NULL ELSE @PriceRate END
			, CASE WHEN @NonBillable = 'Y'THEN NULL ELSE @PriceTotal END
			, @SMPhaseGroup
			, @CostRate * @Hours, @UseAgreementRates, @Agreement--, @OldPostSeq


			--SELECT * FROM SMWorkCompleted WHERE WorkOrder = 6 AND SMCo = 101
			--ORDER BY WorkCompleted DESC

			
		SELECT @SMWorkCompletedID=SMWorkCompletedID FROM SMWorkCompleted WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND Scope=@Scope
			AND Type=@LineType AND WorkCompleted=@WorkCompleted


	END TRY
	
	BEGIN CATCH
		SET @msg = 'mckSMWorkCompletedEquipCreate: ' + ERROR_MESSAGE()
		GOTO error
	END CATCH

   return 0
   error:
   	select @msg = isnull(@msg,'') + ' - cannot insert SM WorkCompletedEquipment!'
   	return 1
	
END

GO
