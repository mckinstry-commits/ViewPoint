SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspAPLBValSM]
	 /******************************************************  
	* CREATED BY:   
	* MODIFIED By:  Mark H - Changed @miscellaneoustype to @smcosttype small int   
	*    JG 01/23/2012  - TK-11971 - Added JCCostType and PhaseGroup, Added NULLs to WorkOrder Val Proc.  
	*    TL 03/15/2012 - TK-13883 - Added Job Phase Validation
	*    TL 04/16/2012 - TK-13994 Added to validation SM Phase from PO Item and validate Cost type to phase
	*    TL 04/24/2012 - TK-14135 Added validation for Tax Code Redirect Phase and JC Cost Type/Changed Taxcode TaxGroup to input paramters
	*	 TL 05/01/2012 - TK-14606 Removed/Changed validation requiring Phase/Tax Redirect Phase from existing in JCJP
	*	 Dan So 05/16/2012 - TK-14641 Check for Soft/Hard Closed jobs
	*	 Dan So 06/22/2012 - TK-15982 Verify JCCostType has a GLAcct before Post
	*	 Matt 01/14/2012 - TK-19963 Remove taxgroup set to null
	*.
	* Usage:  
	*   
	* Input params:  
	*   
	* Output params:  
	* @msg  Code description or error message  
	*  
	* Return code:  
	* 0 = success, 1 = failure  
	*******************************************************/  
	(@smco bCompany, @smworkorder int, @scope int, @smcosttype smallint, @jccosttype bJCCType,   
	@phasegroup bGroup, @phase bPhase, @smtype tinyint, @invdate bDate, @aptlkeyid int,   
	@taxgroup bGroup, @taxcode bTaxCode,
	@smservicesite varchar(20) OUTPUT, @smtaxtype tinyint OUTPUT, @smtaxgroup bGroup OUTPUT, @smtaxcode bTaxCode OUTPUT, @smtaxrate bRate OUTPUT, @errmsg varchar(255) OUTPUT)  
	  
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int, @Taxable bYN, @jcco bCompany, @job bJob, @smworkorderscopephasegroup bGroup, @smworkorderscopephase bPhase,
			@taxredirectphase bPhase, @taxredirectcosttype bJCCType,
			-- TK-15982 --
			@GLAcct bGLAcct

	EXEC @rcode = dbo.vspSMCoVal @SMCo = @smco, @TaxGroup = @smtaxgroup OUTPUT, @msg = @errmsg OUTPUT  
	IF @rcode = 1  
	BEGIN
		RETURN 1
	END

	EXEC @rcode = dbo.vspSMWorkCompletedWorkOrderVal @SMCo = @smco, @WorkOrder = @smworkorder, @IsCancelledOK = 'N', @JCCo = @jcco OUTPUT, @Job = @job OUTPUT, @msg = @errmsg OUTPUT
	IF @rcode <> 0
	BEGIN
		RETURN 1
	END

	EXEC @rcode = dbo.vspSMWorkCompletedScopeVal @SMCo = @smco, @WorkOrder = @smworkorder, @Scope = @scope, @LineType = @smtype, @SMCostType = @smcosttype,
		@DefaultTaxType = @smtaxtype OUTPUT, @DefaultTaxCode = @smtaxcode OUTPUT, @ServiceSite = @smservicesite OUTPUT, @PhaseGroup = @smworkorderscopephasegroup OUTPUT, @Phase = @smworkorderscopephase OUTPUT, @msg = @errmsg OUTPUT
	IF @rcode <> 0
	BEGIN
		RETURN 1
	END

	IF @smcosttype IS NOT NULL
	BEGIN
		EXEC @rcode = dbo.vspSMCostTypeVal @SMCo = @smco, @SMCostType = @smcosttype, @LineType = @smtype, @MustExist = 'Y', @Taxable = @Taxable OUTPUT, @msg = @errmsg OUTPUT
		IF @rcode <> 0
		BEGIN
			RETURN 1
		END
	END

	/* Get the Tax Rate */
	IF @smtype = 3 AND @Taxable = 'Y' AND @smtaxcode IS NOT NULL AND @job IS NULL
	BEGIN
		EXEC @rcode = dbo.vspHQTaxCodeVal @taxgroup = @smtaxgroup, @taxcode = @smtaxcode, @compdate = @invdate, @taxtype = @smtaxtype, @taxrate = @smtaxrate OUTPUT, @msg = @errmsg OUTPUT
		IF @rcode <> 0
		BEGIN
			RETURN 1
		END
	END
	ELSE
	BEGIN
		SELECT @smtaxtype = NULL, @smtaxcode = NULL, @smtaxrate = NULL
	END

	IF @job IS NOT NULL
	BEGIN
		IF @smtype = 3 --SM material PO line
		BEGIN
			IF ISNULL(@smworkorderscopephase,'') = ''
			BEGIN
				SELECT  @errmsg='SM Work Order Scope is missing Job Phase'
				RETURN 1
			END
			IF dbo.vfIsEqual(@smworkorderscopephase, @phase) = 0 OR dbo.vfIsEqual(@smworkorderscopephasegroup, @phasegroup) = 0
			BEGIN
				SELECT  @errmsg='SM Work Order Scope Phase is different from PO Item Phase'
				RETURN 1
			END
		END

		EXEC @rcode = dbo.bspJCVCOSTTYPE @jcco = @jcco, @job = @job, @PhaseGroup = @phasegroup, @phase = @phase, @costtype = @jccosttype, @costtypeout = @jccosttype OUTPUT, @msg = @errmsg OUTPUT  
		IF @rcode <> 0  
		BEGIN
			RETURN 1
		END

		-- TK-15982 --
		EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @jcco, @job = @job, @phasegroup = @phasegroup, @phase = @phase, @costtype = @jccosttype, @override = 'N', @glacct = @GLAcct OUTPUT, @msg = @errmsg OUTPUT  
		IF @rcode <> 0  
		BEGIN
			RETURN 1
		END

		IF @GLAcct IS NULL
		BEGIN
			SET @errmsg = 'Missing GL Account for JCCo:' + dbo.vfToString(@jcco) + 
						  ' , Job:' + dbo.vfToString(@job) + ' , Phase:' + dbo.vfToString(@phase) + 
						  ' , CostType:' + dbo.vfToString(@jccosttype) 
			RETURN 1
		END

		IF @taxcode IS NOT NULL
		BEGIN
			SELECT @taxredirectphase = ISNULL(Phase, @phase), @taxredirectcosttype = ISNULL(JCCostType, @jccosttype) 
			FROM dbo.bHQTX 
			WHERE TaxGroup = @taxgroup AND TaxCode = @taxcode
			
			IF @taxredirectphase <> @phase
			BEGIN
				EXEC @rcode = dbo.bspJCVPHASE @jcco = @jcco, @job = @job, @phase = @taxredirectphase, @phasegroup = @phasegroup, @override = 'N', @msg = @errmsg OUTPUT
				IF @rcode <> 0
				BEGIN
					RETURN 1
				END
			END

			IF @taxredirectcosttype <> @jccosttype
			BEGIN
				EXEC @rcode = dbo.bspJCVCOSTTYPE @jcco = @jcco, @job = @job, @PhaseGroup = @phasegroup, @phase = @taxredirectphase, @costtype = @taxredirectcosttype, @costtypeout = @taxredirectcosttype OUTPUT, @msg = @errmsg OUTPUT  
				IF @rcode <> 0
				BEGIN
					RETURN 1
				END
			END
			
			IF @taxredirectphase <> @phase OR @taxredirectcosttype <> @jccosttype
			BEGIN
				EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @jcco, @job = @job, @phasegroup = @phasegroup, @phase = @taxredirectphase, @costtype = @taxredirectcosttype, @override = 'N', @glacct = @GLAcct OUTPUT, @msg = @errmsg OUTPUT  
				IF @rcode <> 0
				BEGIN
					RETURN 1
				END
				
				IF @GLAcct IS NULL
				BEGIN
					SET @errmsg = 'Missing GL Account for JCCo:' + dbo.vfToString(@jcco) + 
								  ' , Job:' + dbo.vfToString(@job) + ' , Phase:' + dbo.vfToString(@taxredirectphase) + 
								  ' , CostType:' + dbo.vfToString(@taxredirectcosttype) 
					RETURN 1
				END
			END
		END
	END  

	IF @aptlkeyid is not null  
	BEGIN  
		IF EXISTS(
			SELECT 1
			FROM dbo.SMWorkCompleted
				INNER JOIN dbo.SMInvoiceSession ON SMWorkCompleted.SMInvoiceID = SMInvoiceSession.SMInvoiceID
			WHERE SMWorkCompleted.SMCo = @smco AND SMWorkCompleted.WorkOrder = @smworkorder AND SMWorkCompleted.APTLKeyID = @aptlkeyid)
		BEGIN  
			SELECT @errmsg = 'SMCo - ' + dbo.vfToString(@smco) + ', Work Order - ' +  dbo.vfToString(@smworkorder) + ' - Work Completed record is in a pending invoice session, cannot change record.'  
			RETURN 1  
		END
	END  
	 
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspAPLBValSM] TO [public]
GO
