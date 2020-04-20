
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
--	Created:	4/20/11
--	Modified:	Dan So 03/19/2012 - TK-13126 - Return JCCo, Job, Phase, PhaseGroup
--				Dan So 03/21/2012 - TK-13126 - Check for input parameters
--				Matt B 11/13/2012 - TK-18717 - SM WO Scope Phase save issue
--				Jeremiah B 11/15/12 Updated the GL account default so that it uses the new purchase line type
--				JVH	3/29/13       - TFS-44846 - Updated to handle deriving sm gl accounts
--
--	Description:	SM Work Order Scope Val For PO
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderScopeValForPO]
	(@SMCo bCompany, @SMWorkOrder int, @Scope int, 
	 @GLCo bCompany = NULL OUTPUT, @CostAccount bGLAcct = NULL OUTPUT,
	 @JCCo bCompany = NULL OUTPUT, @Job bJob = NULL OUTPUT,
   	 @PhaseGroup bGroup = NULL OUTPUT, @Phase bPhase = NULL OUTPUT,
	 @msg varchar(255) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Division varchar(10), @CallType varchar(10), @ServiceCenter varchar(10), @errortext varchar(255)
	
	IF @SMCo IS NULL
		BEGIN
			SET @msg = 'Missing SMCo'
			RETURN 1
		END
		
	IF @SMWorkOrder IS NULL
		BEGIN
			SET @msg = 'Missing SMWorkOrder'
			RETURN 1
		END
		
	IF @Scope IS NULL
		BEGIN
			SET @msg = 'Missing @Scope'
			RETURN 1
		END
		
	SELECT	@JCCo = JCCo,
			@Job = Job,
			@PhaseGroup = PhaseGroup,
			@Phase = Phase,
			@msg = [Description]
	  FROM	dbo.SMWorkOrderScope
	 WHERE	SMCo = @SMCo AND WorkOrder = @SMWorkOrder and Scope = @Scope
	
	IF (@@rowcount = 0)
	BEGIN
		SELECT @msg = 'Invalid Work Order Scope'
		RETURN 1
	END
	
	SELECT @GLCo = GLCo, @CostAccount = CurrentCostGLAcct
	FROM dbo.vfSMGetAccountingTreatment(@SMCo, @SMWorkOrder, @Scope, 'M', NULL)
	
	IF (@JCCo IS NOT NULL AND @Job IS NOT NULL)
	BEGIN
		--check Job Phases - exact match
		EXEC @rcode = dbo.bspJCVPHASE  @jcco=@JCCo,@job=@Job,@phase=@Phase,@phasegroup=@PhaseGroup,@override= 'N',@msg=@msg output
		IF @rcode <> 0
		BEGIN
			SELECT @errortext = dbo.vfToString(@msg)
			SELECT @msg =  @errortext
			if(@msg LIKE 'Missing Phase!')
				SET @msg = 'The specified scope sequence is missing a phase. Enter a phase for the scope sequence in SM Work Orders before continuing.'
			RETURN 1	
		END
	END

	RETURN 0
END


GO

GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopeValForPO] TO [public]
GO
