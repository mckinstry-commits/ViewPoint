SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMWorkCompletedLaborCreate]   
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/20/2011
-- Description:	Create SMWorkCompleted record for labor from Payrol time entry.
-- Modifications: 01/27/11 Eric V  Modified to only create a single SMWorkCompleted recoord.
--			      03/12/11 Mark H  Added SMGLCo output param to vspSMWorkCompletedScopeVal
--                03/16/11 Eric V  Added Craft, Class and Shift.
--                04/14/11 Eric V  Added @IsTrackingWIP to Work Completed
--                05/04/11 Eric V  Modified for one unique WorkCompleted for all types.
--                07/18/11 Eric V  Added Craft and Class to input parameters for call to vspSMLaborRateGet.
--                07/22/11 Eric V  Set Provisional flag if validation fails.
--                07/27/11 Eric V  Change WIPAccount to CostWIPAccount and added RevenueWIPAccount.
--                08/23/11 Eric V  Added @SMCostType parameter.
--				  01/25/12 Mark H  Added @JCCostType parameter - B-07899
--				  02/09/2012 - JG - TK-12388 - Added @SMJCCostType and @SMPhaseGroup
--				  03/06/2012 - JG - TK-13074 - Added use of the CostingMethod from the Work Order.
--				5/29/12 JeremiahB - Fixed defaulting of Tax fields for Job related work completed.
--				9/4/12 JeremiahB - Defaulted Tax Type based on DefaultCountry
-- =============================================
 @SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10), @SMCostType smallint=null, @Date smalldatetime, @Technician varchar(15), @Hours bHrs,   
 @WorkCompleted int, @SMJCCostType dbo.bJCCType = NULL, @SMPhaseGroup dbo.bGroup = NULL,
 @SMWorkCompletedID int = NULL OUTPUT,   
 @TCPRCo bCompany=NULL, @TCPRGroup bGroup=NULL, @TCPREndDate smalldatetime=NULL, @TCPREmployee bEmployee=NULL,  
 @TCPRPaySeq tinyint=NULL, @TCPRPostSeq smallint=NULL, @TCPRPostDate smalldatetime=NULL, @Craft bCraft=NULL,  
 @Class bClass=NULL, @Shift tinyint=NULL, @msg varchar(255) = NULL OUTPUT  
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @TaxGroup bGroup, @TaxBasic bDollar, @GLCo bCompany, @CostAccount bGLAcct, @RevenueAccount bGLAcct, @RevenueWIPAccount bGLAcct,
			@CostWIPAccount bGLAcct, @CostRate numeric(16,5), @PriceRate numeric(16,5), @NextSeq int, 
			@TaxCode varchar(10), @LineType int, @TaxType int, @DefaultTaxType int, @TaxRate bRate,
			@ServiceSite varchar(20), @rcode int, @PRCo bCompany, @SMGLCo bCompany,
			@Provisional BIT, @CostingMethod VARCHAR(10), @Agreement varchar(15), @Revision int, 
			@Coverage char(1), @Job bJob, @TaxBasis bDollar
			
			
	SET @LineType = 2

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
		@Agreement=@Agreement OUTPUT, @Revision=@Revision OUTPUT, @Coverage=@Coverage OUTPUT, @Job = @Job OUTPUT, 
		@msg=@msg OUTPUT
	IF (@rcode=1)
	BEGIN
		GOTO error
	END
	
	-- Clear out Tax related fields if this is related to a Job
	IF (@Job IS NOT NULL)
	BEGIN
		SELECT @TaxGroup = NULL, @TaxCode = NULL, @TaxType = NULL, @TaxRate = NULL
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
	
	/* Get CostRate and PriceRate */
	EXEC @rcode = vspSMLaborRateGet @SMCo=@SMCo, @Technician=@Technician, @PayType=@PayType, @LaborCostRate=@CostRate OUTPUT, @JCCostType = null, @msg=@msg OUTPUT
	IF (@rcode = 1)
	BEGIN
		goto error
	END
	
	-- Grab CostingMethod of the WorkOrder
	SELECT @CostingMethod = CostingMethod
	FROM dbo.SMWorkOrder
	WHERE SMCo = @SMCo 
		AND WorkOrder = @WorkOrder
	
	-- Determine the Labor Price Rate
	IF @CostingMethod IS NULL OR @CostingMethod <> 'Cost'
	BEGIN
		SELECT @PriceRate = Rate FROM dbo.vfSMRateLabor(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @Coverage, @TCPRCo, @PayType, @Craft, @Class, @Technician)
	END
	ELSE
	BEGIN
		SELECT @PriceRate = @CostRate
	END	
	
	-- Determine Tax Basis
	SELECT @TaxBasis = CASE WHEN @Job IS NOT NULL THEN NULL ELSE @PriceRate * @Hours END
	
	/* Insert records in SMWorkCompleted */
	BEGIN TRY

		INSERT SMWorkCompleted (Type, SMCo, WorkOrder, WorkCompleted, Scope, Date, TaxType, TaxGroup,
			TaxCode, TaxBasis, TaxAmount, GLCo, CostAccount, RevenueAccount, CostWIPAccount, RevenueWIPAccount, 
			Technician, CostQuantity, CostRate, ProjCost, PriceQuantity, PriceRate, PriceTotal, PayType, Craft, 
			Class, Shift, ServiceSite, NoCharge, CostCo, PRCo, PRGroup, PREndDate, PREmployee, PRPaySeq, PRPostSeq, 
			PRPostDate, Provisional, SMCostType, JCCostType, PhaseGroup, Agreement, Revision, Coverage)
		VALUES
			(@LineType, @SMCo, @WorkOrder, @WorkCompleted, @Scope, @Date, @TaxType, @TaxGroup, @TaxCode,
			@TaxBasis, @TaxRate*@PriceRate*@Hours, @SMGLCo, @CostAccount, @RevenueAccount, @CostWIPAccount, @RevenueWIPAccount,
			@Technician, @Hours, @CostRate, @CostRate*@Hours, @Hours, @PriceRate, @PriceRate*@Hours, @PayType, @Craft, @Class, @Shift,
			@ServiceSite, 'N', @TCPRCo, @TCPRCo, @TCPRGroup, @TCPREndDate, @TCPREmployee, @TCPRPaySeq, @TCPRPostSeq, 
			@TCPRPostDate, @Provisional, @SMCostType, @SMJCCostType, @SMPhaseGroup, @Agreement, @Revision, @Coverage)
			
		SELECT @SMWorkCompletedID=SMWorkCompletedID FROM SMWorkCompleted WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND Scope=@Scope
			AND Type=@LineType AND WorkCompleted=@WorkCompleted
	END TRY
	
	BEGIN CATCH
		SET @msg = 'vspSMWorkCompletedLaborCreate: ' + ERROR_MESSAGE()
		GOTO error
	END CATCH

   return 0
   error:
   	select @msg = isnull(@msg,'') + ' - cannot insert SM WorkCompletedLabor!'
   	return 1
	
END




GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedLaborCreate] TO [public]
GO
