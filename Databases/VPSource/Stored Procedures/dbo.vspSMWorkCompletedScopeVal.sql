
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspSMWorkCompletedScopeVal]
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/10/2010
-- Description:	Validation for the scope on work completed records.
-- Modifications:
--		01/10/11 EricV - Added change for Rate Template and Call Type.
--		03/12/11 MarkH - Added SMGLCo output parameter
--		03/15/11 EricV - Added Craft, Class and Shift
--		03/23/11 LaneG -
--		04/18/11 MarkH - Replaced GL Default code with call to function vfSMGetAccountingTreatment
--      07/22/11 EricV - Do not return until all values have been set, even if error occurs.
--		07/28/11 JeremiahB - Modified to use new accounting treatment with cost type.
--		01/18/12 JasonG - TK-11866 - Validating the Scope contains a phase.
--		01/20/12 TerryL - TK-11927  Add Job and Phase out paramters (JCCo and PhaseGroup are defaulted from form load proc)
--		02/02/12 JasonG - TK-11970 - Returning the PhaseGroup.
--		05/22/12 EricV  - TK-14637 Require a Phase code for job work orders so that the correct pay based on the job can be determined.
--		08/06/12 LaneG  - TK-16771 Added validation for the Phase
--      09/05/12 Jeremiah B - Added the TaxTypeDefault output param
--		10/04/12 Matthew B	- TK-18335 Modified the call to  bspJCVPHASE to use @newmessage and not overwrite @msg with the wrong error.
--		3/29/13	JVH		- TFS-44846 - Updated to handle deriving sm gl accounts
--      05/21/13 EricV  - TFS-50951 - Check for PriceMethod value of 'N' instead of 'C'
--      05/31/13 EricV  - TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
--		06/06/13 JVH	- TFS-50962 Need indicate if work order is agreement,or spot agreement on work compelted forms
--      06/24/13 EricV  - TFS-52109 Change to not report an error when the Labor record has been posted.
--		07/03/13 MTB	- TFS-54655 Update to fix issue with saving work completed lines without a rate template

-- =============================================
	@SMCo bCompany, 
	@WorkOrder int, 
	@Scope int, 
	@LineType tinyint, 
    @AllowProvisional bYN = 'N',
	@WorkCompleted int=NULL,
	@SMCostType smallint = NULL,
	@DefaultCostAcct bGLAcct = NULL OUTPUT, 
	@DefaultRevenueAcct bGLAcct = NULL OUTPUT, 
	@DefaultCostWIPAcct bGLAcct = NULL OUTPUT,
	@DefaultRevWIPAcct bGLAcct = NULL OUTPUT,
	@DefaultTaxType int = NULL OUTPUT, 
	@DefaultTaxCode bTaxCode = NULL OUTPUT, 
	@ServiceSite varchar(20) = NULL OUTPUT, 
	@SMGLCo bCompany = NULL OUTPUT, 
	@IsTrackingWIP bYN = NULL OUTPUT,
	@IsScopeCompleted bYN = NULL OUTPUT, 
	@Job bJob = NULL OUTPUT,
    @Phase bPhase = NULL OUTPUT,
    @PhaseGroup bGroup = NULL OUTPUT,
    @Agreement varchar(15) = NULL OUTPUT,
    @Revision int = NULL OUTPUT,
    @NonBillable bYN = NULL OUTPUT,
    @IsAgreement bYN = NULL OUTPUT,
    @UseAgreementRates bYN = NULL OUTPUT,
	@ScopePriceMethod char(1) = NULL OUTPUT,
	@ScopeType INT = NULL OUTPUT,
    @Provisional bit = 0 OUTPUT,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @ErrorOccured int, @NewMsg as varchar(255), @CostingMethod varchar(15), @ScopeAgreement varchar(15), @WorkOrderQuote varchar(15), @Service int
	SELECT @rcode=0, @ErrorOccured = 0
	
	EXEC @rcode = vspSMWorkOrderScopeVal @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @MustExist='Y', @msg=@msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		-- Don't skip the rest of the code which is needed to set default values.
		SET @ErrorOccured = @rcode
	END
	
	DECLARE @RateTemplate varchar(10), @CallType varchar(10), @ServiceCenter varchar(10), @JCCo bCompany
	
	-- Determine the Service Center, Division and Call Type that will be used to retrieve the accounting treatment
	SELECT	@ServiceCenter = SMWorkOrder.ServiceCenter, 
			@JCCo = SMWorkOrder.JCCo,
			@RateTemplate = SMWorkOrderScope.RateTemplate, 
			@CallType = SMWorkOrderScope.CallType,
			@IsTrackingWIP = SMWorkOrderScope.IsTrackingWIP, 
			@IsScopeCompleted = SMWorkOrderScope.IsComplete, 
			@Phase = SMWorkOrderScope.Phase,
			@Job = SMWorkOrderScope.Job, 
			@PhaseGroup = SMWorkOrderScope.PhaseGroup,
			@CostingMethod = SMWorkOrder.CostingMethod,
			@ScopeAgreement = SMWorkOrderScope.Agreement,
			@ScopePriceMethod = SMWorkOrderScope.PriceMethod,
			@Service = SMWorkOrderScope.[Service],
			@Agreement = SMWorkOrderScope.Agreement,
			@Revision = SMWorkOrderScope.Revision,
			@NonBillable = CASE
							WHEN SMWorkOrderScope.PriceMethod = 'N' THEN 'Y'
							WHEN SMWorkOrderScope.PriceMethod = 'F' THEN 'Y'
							ELSE NULL END,		
			@IsAgreement = CASE WHEN SMWorkOrderScope.Agreement IS NOT NULL THEN 'Y' ELSE 'N' END,
			@UseAgreementRates = SMWorkOrderScope.UseAgreementRates,
			@DefaultTaxType = CASE WHEN HQCO.DefaultCountry = 'AU' OR HQCO.DefaultCountry = 'CA' THEN 3 ELSE 1 END,
			@SMGLCo = vfSMGetAccountingTreatment.GLCo,
			@DefaultCostAcct = vfSMGetAccountingTreatment.CostGLAcct,
			@DefaultRevenueAcct = vfSMGetAccountingTreatment.RevenueGLAcct,
			@DefaultCostWIPAcct = vfSMGetAccountingTreatment.CostWIPGLAcct,
			@DefaultRevWIPAcct = vfSMGetAccountingTreatment.RevenueWIPGLAcct,
			@WorkOrderQuote = SMWorkOrderScope.WorkOrderQuote,
			@ScopeType = 
				CASE
					WHEN SMWorkOrderScope.Agreement IS NOT NULL AND SMWorkOrderScope.[Service] IS NULL THEN 2
					WHEN SMWorkOrderScope.Agreement IS NOT NULL AND SMWorkOrderScope.[Service] IS NOT NULL THEN 3
					WHEN SMWorkOrderScope.WorkOrderQuote IS NOT NULL THEN 4
					ELSE 1
				END
	FROM dbo.SMWorkOrderScope 
		INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo=SMWorkOrderScope.SMCo AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
		INNER JOIN dbo.SMCO ON SMCO.SMCo = SMWorkOrderScope.SMCo
		INNER JOIN dbo.HQCO ON HQCO.HQCo = SMCO.ARCo
		LEFT JOIN dbo.SMWorkCompleted ON SMWorkOrderScope.SMCo = SMWorkCompleted.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkCompleted.WorkOrder AND SMWorkCompleted.WorkCompleted = @WorkCompleted		
		CROSS APPLY dbo.vfSMGetAccountingTreatment (SMWorkOrderScope.SMCo, SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope, CASE @LineType WHEN 1 THEN 'E' WHEN 2 THEN 'L' WHEN 3 THEN CASE WHEN SMWorkCompleted.APTLKeyID IS NOT NULL THEN 'M' ELSE 'O' END WHEN 4 THEN 'M' WHEN 5 THEN 'M' END, @SMCostType)
	WHERE SMWorkOrderScope.SMCo = @SMCo AND SMWorkOrderScope.WorkOrder = @WorkOrder AND SMWorkOrderScope.Scope = @Scope 
	
	DECLARE @cnt SMALLINT, @missing VARCHAR(MAX)
	DECLARE @MissingTable TABLE (NAMES VARCHAR(150))

	-- Only change the error message if this is the first error encountered.
	IF @ErrorOccured = 0
	BEGIN		
		SELECT @cnt = 0, @msg = ''
		
		IF (@ServiceCenter IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Service Center') 
		END
					
		-- Check for Missing Rate Template on Job work orders. Only required where the Costing Method is Revenue.
		IF (@Job IS NOT NULL AND @CostingMethod='Revenue' AND @NonBillable='N' AND @RateTemplate IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Rate Template') 
		END
		-- Check for Missing Rate Template on Agreement work orders. Only required where the Scope Price Method is Time & Material.
		ELSE IF (@ScopeAgreement IS NOT NULL AND @ScopePriceMethod='T' AND @UseAgreementRates='N' AND @RateTemplate IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Rate Template') 
		END
		-- Check for Missing Rate Template on Customer work orders. Rate Template is always required.
		ELSE IF (@ScopeAgreement IS NULL AND @WorkOrderQuote IS NULL AND @Job IS NULL AND @NonBillable='N' AND @RateTemplate IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Rate Template') 
		END
		-- Check if Scope is T & M and service is null. Rate Template required.
		ELSE IF((@Job IS NULL OR (@Job IS NOT NULL AND @CostingMethod='Revenue')) AND @ScopePriceMethod='T' AND @Service IS NULL AND @RateTemplate IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Rate Template') 
		END

		IF (@CallType IS NULL)
		BEGIN
			INSERT INTO @MissingTable (NAMES) VALUES ('Call Type') 
		END
		
		IF (@Job IS NOT NULL)
		BEGIN
			EXEC @rcode = bspJCVPHASE @jcco = @JCCo, @job = @Job, @phase = @Phase, @phasegroup = @PhaseGroup, @msg = @NewMsg OUTPUT
			IF @rcode <> 0
			BEGIN
				-- Don't skip the rest of the code which is needed to set default values.
				SET @ErrorOccured = @rcode
				SET @msg = @NewMsg
			END
		END
	
		-- Check to see if an error was found and build the error message.
		IF EXISTS(SELECT 1 FROM @MissingTable)
		BEGIN
			IF (@AllowProvisional='Y')
			BEGIN
				SELECT @Provisional=1
			END
			ELSE
			BEGIN
			
				-- Run through records until table is empty
				WHILE EXISTS (SELECT 1 FROM @MissingTable)
				BEGIN
					-- Get the first record
					SELECT TOP 1 @missing = NAMES FROM @MissingTable
				
					-- Set or Append new missing data
					SET @msg = CASE WHEN @cnt = 0 THEN @missing
									WHEN @cnt = 1 THEN @missing + ' and ' + @msg
									ELSE @missing + ', ' + @msg END
				
					SET @cnt = @cnt + 1
					
					-- Delete the record
					DELETE FROM @MissingTable WHERE NAMES = @missing
				END
				
				-- If just one field missing - is - otherwise - are for proper grammar.
				SET @msg = CASE WHEN @cnt = 1 THEN @msg + ' is'
							ELSE @msg + ' are' END
				
				-- End by setting that the fields are required					
				SET @msg = @msg + ' needed before Work Completed can be entered for this scope.'
				SELECT @rcode=1, @Provisional=1
			END
		END
		ELSE IF (@AllowProvisional='Y')
		BEGIN
			-- Set Provisional to 1 unless other non-provisional exist for the scope
			IF NOT EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder and Scope = @Scope AND Provisional = 0)
				SELECT @Provisional = 1
		END
	END
	
	IF @rcode <> 0 AND @ErrorOccured=0
	BEGIN
		SET @ErrorOccured = @rcode
	END
	
	IF (@LineType=2 AND NOT ISNULL(@WorkCompleted,0)=0)
	BEGIN
		/* Check for locked records due to Payroll */
		DECLARE @PRPostDate smalldatetime, @SMBCID bigint, @OldScope int
		
		SELECT @PRPostDate=PRPostDate, @SMBCID=PayrollLink.SMBCID, @OldScope=PayrollLink.Scope
		FROM SMWorkCompleted
			LEFT JOIN vSMBC PayrollLink ON SMWorkCompleted.SMCo=PayrollLink.SMCo
				AND SMWorkCompleted.WorkOrder=PayrollLink.WorkOrder
				AND SMWorkCompleted.WorkCompleted=PayrollLink.WorkCompleted
			WHERE SMWorkCompleted.SMCo=@SMCo AND SMWorkCompleted.WorkOrder=@WorkOrder 
				AND SMWorkCompleted.Scope=@Scope AND Type=2 
				AND SMWorkCompleted.WorkCompleted=@WorkCompleted
		
		IF (NOT @SMBCID IS NULL AND NOT @OldScope=@Scope)
		BEGIN
			SELECT @rcode=1
			IF @ErrorOccured=0
				SELECT @msg = 'Related timecard record is in a batch.'
		END		
		IF @rcode <> 0 AND @ErrorOccured=0
		BEGIN
			SET @ErrorOccured = @rcode
		END
	END
	
	DECLARE @SaleLocation tinyint
	
	SELECT @SaleLocation = SMWorkOrderScope.SaleLocation, @ServiceSite = SMWorkOrder.ServiceSite
	FROM dbo.SMWorkOrderScope
		INNER JOIN dbo.SMWorkOrder ON SMWorkOrderScope.SMCo = SMWorkOrder.SMCo AND 
		SMWorkOrderScope.WorkOrder = SMWorkOrder.WorkOrder
	WHERE SMWorkOrderScope.SMCo = @SMCo AND SMWorkOrderScope.WorkOrder = @WorkOrder AND 
	SMWorkOrderScope.Scope = @Scope

	--Grab the default tax code based on the sale location
     IF ISNULL(@Job,'')<>''
          SELECT @DefaultTaxCode = NULL
     ELSE IF @SaleLocation = 0 --The sale happened at the service center
     BEGIN

		SELECT @DefaultTaxCode = TaxCode
		FROM dbo.SMServiceCenter
			INNER JOIN dbo.SMWorkOrder ON SMServiceCenter.SMCo = SMWorkOrder.SMCo AND SMServiceCenter.ServiceCenter = SMWorkOrder.ServiceCenter
		WHERE SMWorkOrder.SMCo = @SMCo AND SMWorkOrder.WorkOrder = @WorkOrder
	END
	ELSE IF @SaleLocation = 1 --The sale happened at the service site
	BEGIN
		SELECT @DefaultTaxCode = TaxCode
		FROM dbo.SMServiceSite
			INNER JOIN dbo.SMWorkOrder ON SMServiceSite.SMCo = SMWorkOrder.SMCo AND SMServiceSite.ServiceSite = SMWorkOrder.ServiceSite
		WHERE SMWorkOrder.SMCo = @SMCo AND SMWorkOrder.WorkOrder = @WorkOrder
	END

vcsexit:	
	IF (@ErrorOccured=0)
	BEGIN
		RETURN @rcode
	END
	ELSE
	BEGIN
		RETURN @ErrorOccured
	END
END
GO

GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedScopeVal] TO [public]
GO
