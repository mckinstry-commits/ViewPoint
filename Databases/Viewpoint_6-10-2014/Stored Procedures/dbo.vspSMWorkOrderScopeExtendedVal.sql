SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[vspSMWorkOrderScopeExtendedVal]
/******************************************************
	* CREATED BY:	Dan K 
	* MODIFIED By:  
	* 
	* Usage:  Validates a work order scope, intended for use on the Work order scope speficially. This is 
	*			reduce the impact of changes on other usages of the scope validation proc that is called 
	*			during this process. 
	*	
	*
	* Input params:
	*
	*	@SMCo         - SM Company
	*	@WorkOrder	  - Work Order
	*   @Scope		  - Work Order Scope number
	*	@MustExist    - Flag to control validation behavior
	*	
	*
	* Output params:
	*	@HasWorkCompleted	- 'Y' if the work order scope has related work completed, otherwise, 'N'.
	*	@Status				- Scope Status
	*	@msg				- Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
(	@SMCo							bCompany,
	@WorkOrder						INT,
   	@Scope							INT,
	@MustExist						dbo.bYN = 'N',
	@TaxSource						INT,
	@TaxRate						dbo.bRate = NULL,
	@TaxGroup						dbo.bGroup = NULL OUTPUT,
	@TaxCode						dbo.bTaxCode = NULL OUTPUT, 
   	@BillToARCustomer				bCustomer = NULL OUTPUT,
   	@RateTemplate					VARCHAR(10) = NULL OUTPUT,
   	@HasWorkCompleted				dbo.bYN='N' OUTPUT,
   	@IsComplete						dbo.bYN = NULL OUTPUT,
   	@CustomerPOSetting				CHAR(1) = NULL OUTPUT,
   	@JCCo							dbo.bCompany = NULL OUTPUT,
   	@Job							dbo.bJob = NULL OUTPUT,
   	@Phase							dbo.bPhase = NULL OUTPUT,
   	@PhaseGroup						dbo.bGroup = NULL OUTPUT,
   	@HasProvisionalWorkCompleted	dbo.bYN='N' OUTPUT,
   	@HasDeletedWorkCompleted		dbo.bYN = 'N' OUTPUT,
   	@ScopeHasInvoices				dbo.bYN = 'N' OUTPUT,
	@TaxAmount						dbo.bDollar = NULL OUTPUT,
   	@msg							VARCHAR(100) = NULL OUTPUT)  

AS 
BEGIN 
	DECLARE @rcode INT

	-- Execute the original vspSMWorkOrderScopeVal proc
	EXEC @rcode = dbo.vspSMWorkOrderScopeVal @SMCo, @WorkOrder, @Scope, 'N', @BillToARCustomer = @BillToARCustomer OUTPUT, @RateTemplate = @RateTemplate OUTPUT, @HasWorkCompleted = @HasWorkCompleted OUTPUT, @IsComplete = @IsComplete OUTPUT, @CustomerPOSetting = @CustomerPOSetting OUTPUT, @JCCo = @JCCo OUTPUT, @Job = @Job OUTPUT, @Phase = @Phase OUTPUT, @PhaseGroup = @PhaseGroup OUTPUT, @HasProvisionalWorkCompleted = @HasProvisionalWorkCompleted OUTPUT, @HasDeletedWorkCompleted = @HasDeletedWorkCompleted OUTPUT, @ScopeHasInvoices = @ScopeHasInvoices OUTPUT, @msg = @msg OUTPUT
	
	-- If there was an error bail out, otherwise move on
	IF @rcode <> 0
	BEGIN 
		RETURN @rcode
	END 
	
	IF @TaxSource = 0 
	-- Tax Source = Service Center 
	BEGIN 
		SELECT		@TaxCode = SC.TaxCode,
					@TaxGroup = SC.TaxGroup
		FROM		SMServiceCenter SC
		INNER JOIN	SMWorkOrder WO
				ON	WO.SMCo = SC.SMCo
				AND WO.ServiceCenter = SC.ServiceCenter
		WHERE		WO.SMCo = @SMCo 
				AND WO.WorkOrder = @WorkOrder
	END 
	ELSE 
	-- Tax Source = Service Site
	BEGIN 
		SELECT		@TaxCode  = SS.TaxCode, 
					@TaxGroup = SS.TaxGroup 
		FROM		SMServiceSite SS
		INNER JOIN	SMWorkOrder WO
				ON	WO.SMCo = SS.SMCo 
				AND WO.ServiceSite = SS.ServiceSite
		WHERE		WO.SMCo = @SMCo 
				AND WO.WorkOrder = @WorkOrder
	END 

	IF @TaxRate IS NOT NULL
	BEGIN 
		-- If there was a successfull return of a Tax Rate the Tax Amount is then calculated  
		SET @TaxAmount = (	SELECT		SUM(RS.Amount * @TaxRate)								
							FROM		SMFlatPriceRevenueSplit RS
							INNER JOIN	SMEntity E 
									ON	E.SMCo = RS.SMCo 
									AND E.EntitySeq = RS.EntitySeq
							INNER JOIN	SMWorkOrderScope S
									ON	S.SMCo = E.SMCo
									AND S.WorkOrder = E.WorkOrder
									AND S.Scope = E.WorkOrderScope
							WHERE		RS.SMCo = @SMCo 
									AND S.WorkOrder = @WorkOrder
									AND S.Scope = @Scope
									AND RS.Taxable = 'Y')
	END 
	ELSE 
	BEGIN
		-- If there is no Tax Code, set the amount back to NULL. This is because there may be a previous value that we want to clear. 
		SET @TaxAmount = NULL 
	END 
END				
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopeExtendedVal] TO [public]
GO
