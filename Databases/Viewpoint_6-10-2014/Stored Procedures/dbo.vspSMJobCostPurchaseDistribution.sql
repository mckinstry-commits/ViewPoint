SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:  TRL 
-- Create date: 02/20/12
-- Description:	TK-12747 Used to create a Job Cost Detail transaction for SM Work Orders associated with Job.
--called from vspSMWorkCompletedAPUpdate
-- Modifications:  03/02/2012 TL TK-12858 added new code for dealing with the @OldNew parameter
--						03/19/2012 TL TK - 13408 fixed code for SM/JC TaxCode Phase/Cost Redirect
--						04/04/2012 TL  TK-13744  Added column PO POItem,POItemLine, VendorGroup,Vendor1
--						04/30/2012  TL  TK-14603 Added column PostRemCmUnits,RemainCmtdCost,RemCmtdTax
--						05/16/2012 TL  TK-14962 No longer return error when no SM Work Completed Record exists
--						05/16/2012 TL  TK-14606 using vspJCVCOSTTYPE for get JobPhaseCostTypeUM
--						05/18/2012 TL  TK-14139 Fix actual unit cost 
--						05/21/2012 TL  TK-15003 Fixed Unit of conversion
--						05/22/2012 TL  TK-15003 Fixed Divide by 0 error for LS transactions and transaction with UM's that don't exist in HQMU and and added Column RemainCmtdUnits
--						05/22/2012 TL  TK-14139 Added POItem Cur Unit Cost to fix Remain Cmtd Cost
--						05/25/2012 TL TK-15053 added @JCTransType Parameter for vspSMJobCostDistributionInsert
--						05/30/2012	JB TK-15066 Removed inserting and handling taxes because taxes were removed from the job work orders
--						05/30/2012 TL  TK-14139 Added fix Remain Cmtd Cost 
--						06/04/2012 TL TK-15003 Refactor and change remain committed costs and posted unit cost and included Vendor/VendorGroup in update.  
--						06/05/2012 TL TK-15003 Refactor and change remain committed costs and posted unit cost after SMAP update.  
--						06/20/2012 TL TK-15938  changed code to to calculate JC ActualUnits
--						06/27/2012 TL TK-15938	changed JC Calcs  for EM Equipment
--						07/172012	  TL TK-16420  Maded PostedUM=to JC Cost Type UM when Posted UM is null
--						07/17/2012 TL  TK-16418	Added ECM Factor to calculate Remain Commtted Cost and Made UM and ECM Coversion for JC Cost with Match HQ Addl Material UM's	
--						05/31/13 EricV TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
--						06/27/13 EricV TFS-50101 Update the GL Interface Level when inserting into vSMDetailTransaction

-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostPurchaseDistribution]
	 @SMWorkCompletedID bigint, @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @GrossAmount bDollar, @TaxBasis bDollar, @TaxAmount bDollar, @msg varchar(255) = NULL OUTPUT
AS
	SET NOCOUNT ON;

	DECLARE @rcode int,
		@JCCo bCompany, @Job bJob,@Phase bPhase,@PhaseGroup bGroup, @JCCostType bJCCType, @JobPhaseCostTypeUM bUM, 
		@OldJCCo bCompany,@OldJCMth bMonth, @OldJCTrans bTrans, @OldJCCostTaxTrans bTrans,
		@PostedUM bUM, @PostedUnits bUnits, @JCActualCost bDollar, 
		@Date bDate, @WorkCompletedDescription varchar(60), @GLEntryID bigint, @BatchSeq int, @JCCostEntryID bigint,
		@TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxPhase bPhase, @TaxCostType bJCCType,@IsTaxRedirect bit, @RemCmtdTaxAmount bDollar,
		@JCActualUnits bUnits,@MatlGroup bGroup,@Material bMatl,@RemainCmtdCost bDollar,
		@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int,
		@RateBasis char(1), @RateMarkup bUnitCost,
		@VendorGroup bGroup, @Vendor bVendor,
		@JCUM bUM, @dbtGLAcct bGLAcct, @GLInterfaceLevel tinyint

	/*Get SM Work Order Info*/			
	SELECT @JCCo = SMWorkOrderScope.JCCo, @Job = SMWorkOrderScope.Job, @Phase = SMWorkOrderScope.Phase,	
		@PhaseGroup = SMWorkCompletedAllCurrent.PhaseGroup, @JCCostType = SMWorkCompletedAllCurrent.JCCostType, 
		--Used for change and delete records.  Links SMWorkCompletedID to JCCD detail record
		@OldJCCo = SMWorkCompletedAllCurrent.JCCo,@OldJCMth = SMWorkCompletedAllCurrent.JCMth, @OldJCTrans = SMWorkCompletedAllCurrent.JCCostTrans,
		--Links to JCCD tax code-redirect phase/cost type
		@OldJCCostTaxTrans = SMWorkCompletedAllCurrent.JCCostTaxTrans,
		--Used to determine if Actual Units Posted.  Posted UM is compared with JC Job/Phase/Cost Types (JCCH)
		@PostedUM = SMWorkCompletedAllCurrent.UM,
		@PostedUnits = SMWorkCompletedAllCurrent.ActualUnits,
		@JCActualCost = vfSMRatePurchase.PriceTotal,
		@MatlGroup = SMWorkCompletedAllCurrent.MatlGroup, @Material = SMWorkCompletedAllCurrent.Part,
		@Date = SMWorkCompletedAllCurrent.[Date],
		@WorkCompletedDescription = SMWorkCompletedAllCurrent.[Description],
		@POCo = SMWorkCompletedAllCurrent.POCo, @PO = SMWorkCompletedAllCurrent.PO, @POItem = SMWorkCompletedAllCurrent.POItem, @POItemLine = SMWorkCompletedAllCurrent.POItemLine,
		@RateBasis = vfSMRatePurchase.Basis, @RateMarkup = ISNULL(vfSMRatePurchase.MarkupPercent / 100 + 1, 1),
		@GLInterfaceLevel = CASE WHEN vSMCO.UseJCInterface='N' THEN 0 ELSE ISNULL(bJCCO.GLCostLevel, 0) END
	FROM dbo.SMWorkCompletedAllCurrent
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkOrderScope.SMCo = SMWorkCompletedAllCurrent.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkCompletedAllCurrent.WorkOrder AND SMWorkOrderScope.Scope = SMWorkCompletedAllCurrent.Scope
		CROSS APPLY dbo.vfSMRatePurchase(SMWorkCompletedAllCurrent.SMCo, SMWorkCompletedAllCurrent.WorkOrder, SMWorkCompletedAllCurrent.Scope, SMWorkCompletedAllCurrent.[Date], SMWorkCompletedAllCurrent.Agreement, SMWorkCompletedAllCurrent.Revision, SMWorkCompletedAllCurrent.NonBillable, SMWorkCompletedAllCurrent.UseAgreementRates, SMWorkCompletedAllCurrent.MatlGroup, SMWorkCompletedAllCurrent.Part, SMWorkCompletedAllCurrent.UM, SMWorkCompletedAllCurrent.ActualUnits, SMWorkCompletedAllCurrent.ActualCost, SMWorkCompletedAllCurrent.PriceUM, SMWorkCompletedAllCurrent.PriceECM)
		INNER JOIN dbo.bJCCO ON bJCCO.JCCo = SMWorkOrderScope.JCCo
		INNER JOIN dbo.vSMCO ON vSMCO.SMCo = SMWorkOrderScope.SMCo
	WHERE SMWorkCompletedAllCurrent.SMWorkCompletedID = @SMWorkCompletedID

	--If no Job in SM Work Order or JC Job Master exit procedure
	IF NOT EXISTS (SELECT 1 FROM dbo.JCJM WHERE JCCo = @JCCo AND Job = @Job)
	BEGIN
		RETURN 0
	END

	DECLARE @GLDistributions TABLE (Trans int, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc, DetailTransGroup int NULL)

	SELECT @BatchSeq = ISNULL(MAX(BatchSeq), 0) + 1
	FROM dbo.vSMWorkCompletedBatch
	WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	
	INSERT dbo.vSMWorkCompletedBatch (SMWorkCompletedID, BatchCo, BatchMonth, BatchId, BatchSeq)
	VALUES (@SMWorkCompletedID, @BatchCo, @BatchMth, @BatchId, @BatchSeq)

	/*Create (change/delete) reversing record in Job Cost Detail to back out old entry
	Check for the change/delete trans first  inserts the reversal tran next to the the 
	original trans being changed or deleted JCCD insert procedure needs the records 
	in order when assigning JC cost transaction numbers.*/

	IF @OldJCTrans IS NOT NULL 
	BEGIN
		/* Create reversing from Job Cost Detail Detail record */
		BEGIN TRY
		
			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID, IsReversingEntry, IsTaxRedirect, BatchCo,  BatchMth,  BatchID, SMCo, SMWorkOrder, SMScope,
				JCCo, Job, Phase, PhaseGroup, CostType, JobPhaseCostTypeUM, [Description], PostedDate,
				POCo, PO, POItem, POItemLine, VendorGroup, Vendor,
				MatlGroup, Material, PostedUM, PECM,
				ActualUnitCost, ActualUnits, ActualCost,
				PostedUnits, PostedUnitCost, PostedECM,
				TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
				PostRemCmUnits, RemainCmtdUnits, RemainCmtdCost, RemCmtdTax, JCTransType)

			SELECT SMWorkCompletedID, 1 IsReversingEntry, 0 IsTaxRedirect, @BatchCo, @BatchMth, @BatchId, SMCo, SMWorkOrder, SMScope,
				JCCo, Job, Phase, PhaseGroup, CostType, UM, [Description], PostedDate,
				APCo, PO, POItem, POItemLine, VendorGroup, Vendor,
				MatlGroup, Material, PostedUM, PerECM,
				ISNULL(ActualUnitCost, 0), ISNULL(-ActualUnits, 0),  ISNULL(-ActualCost, 0),
				ISNULL(-PostedUnits, 0), ISNULL(PostedUnitCost, 0), PostedECM,
				TaxType, TaxGroup, TaxCode, ISNULL(-TaxBasis, 0), ISNULL(-TaxAmt, 0),
				-PostRemCmUnits, -RemainCmtdUnits, -RemainCmtdCost, -RemCmtdTax, JCTransType
			FROM dbo.JCCD 
			WHERE JCCo=@OldJCCo AND Mth=@OldJCMth AND CostTrans=@OldJCTrans 
		END TRY
		BEGIN CATCH
			SET @msg = 'Failed to create reversing Job Cost Detail distribution record: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
		
		/* Create reversing TaxCode Phase/CostType Redirect Job Cost Detail Detail record */
		IF @OldJCCostTaxTrans IS NOT NULL
		BEGIN
			BEGIN TRY
				INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID, IsReversingEntry, IsTaxRedirect, BatchCo,  BatchMth,  BatchID, SMCo, SMWorkOrder, SMScope,
					JCCo, Job, Phase, PhaseGroup, CostType, [Description], PostedDate,
					POCo, PO, POItem, POItemLine, VendorGroup, Vendor,
					MatlGroup, Material,
					ActualCost,  RemainCmtdCost,
					TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
					RemCmtdTax, JCTransType)

				SELECT SMWorkCompletedID, 1 IsReversingEntry, 1 IsTaxRedirect, @BatchCo, @BatchMth, @BatchId, SMCo, SMWorkOrder, SMScope,
					JCCo, Job, Phase, PhaseGroup, CostType, [Description], PostedDate,
					APCo, PO, POItem, POItemLine, VendorGroup, Vendor,
					MatlGroup, Material,
					-ActualCost,  -RemainCmtdCost,
					TaxType, TaxGroup, TaxCode, -TaxBasis, -TaxAmt,
					-RemCmtdTax, JCTransType
				FROM dbo.JCCD 
				WHERE JCCo = @OldJCCo AND Mth = @OldJCMth AND CostTrans = @OldJCCostTaxTrans
			END TRY
			BEGIN CATCH
				SET @msg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' + ERROR_MESSAGE()
				RETURN 1
			END CATCH
		END

		INSERT dbo.vSMDetailTransaction (IsReversing, Posted, GLInterfaceLevel, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
		SELECT 1 IsReversing, 1 Posted, @GLInterfaceLevel, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 5 LineType, 'R' TransactionType, @BatchCo, @BatchMth, @BatchId, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, -vGLEntryTransaction.Amount
		FROM dbo.SMWorkCompleted
			INNER JOIN dbo.vSMWorkCompleted ON SMWorkCompleted.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			INNER JOIN dbo.vSMWorkCompletedGLEntry ON ISNULL(vSMWorkCompleted.RevenueSMWIPGLEntryID, vSMWorkCompleted.RevenueGLEntryID) = vSMWorkCompletedGLEntry.GLEntryID
			INNER JOIN dbo.vGLEntryTransaction ON vSMWorkCompletedGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND vSMWorkCompletedGLEntry.GLTransactionForSMDerivedAccount = vGLEntryTransaction.GLTransaction
			INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
			INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		WHERE SMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID

		INSERT @GLDistributions
		SELECT ROW_NUMBER() OVER(ORDER BY vGLEntryTransaction.GLEntryID, vGLEntryTransaction.GLTransaction), GLCo, GLAccount, -Amount, [Description], NULL
		FROM dbo.vSMWorkCompleted
			LEFT JOIN dbo.vSMWorkCompletedGLEntry RevenueGLEntry ON vSMWorkCompleted.RevenueGLEntryID = RevenueGLEntry.GLEntryID
			LEFT JOIN dbo.vSMWorkCompletedGLEntry RevenueSMWIPGLEntry ON vSMWorkCompleted.RevenueSMWIPGLEntryID = RevenueSMWIPGLEntry.GLEntryID
			INNER JOIN dbo.vGLEntryTransaction ON
				--If no SM WIP has been done then include all transactions otherwise include all transactions but the account that had WIP transferred out of.
				(RevenueGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND (RevenueSMWIPGLEntry.GLEntryID IS NULL OR RevenueGLEntry.GLTransactionForSMDerivedAccount <> vGLEntryTransaction.GLTransaction)) OR
				--Only included the transaction that WIP was transferred to.
				(RevenueSMWIPGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND RevenueSMWIPGLEntry.GLTransactionForSMDerivedAccount = vGLEntryTransaction.GLTransaction) OR
				--Include all transactions related to Job WIP as it will keep track of all transactions coming from Job WIP on the same GL Entry until a change to the work completed record.
				vSMWorkCompleted.RevenueJCWIPGLEntryID = vGLEntryTransaction.GLEntryID
		WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID 
		
		IF @@rowcount > 0
		BEGIN
			EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @msg OUTPUT

			IF @GLEntryID = -1 RETURN 1

			INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
			VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @OldJCCo)
			
			EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @msg = @msg OUTPUT
			
			IF @JCCostEntryID = -1 RETURN 1
			
			UPDATE dbo.vSMWorkCompletedBatch
			SET ReversingRevenueGLEntryID = @GLEntryID, ReversingJCCostEntryID = @JCCostEntryID
			WHERE SMWorkCompletedID = @SMWorkCompletedID

			INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @GLEntryID, Trans, GLCo, GLAccount, Amount, @Date, [Description]
			FROM @GLDistributions
		END
	END

	--Prevents JCCD record being created when no AP Trans exist
	--Prevents JCCD record from being created when deleting AP Invoice Trans
	IF @JCActualCost = 0
	BEGIN
		RETURN 0
	END

	DECLARE @JCGLCo bCompany, @GLCostDetailDesc varchar(60), @TransDesc varchar(60), @SMGLCo bCompany, @SMGLAcct bGLAcct, @JCGLAcct bGLAcct, @ARGLAcct bGLAcct, @APGLAcct bGLAcct

	DELETE @GLDistributions

	-- Validates that the phase is active
	EXEC @rcode = dbo.bspJCVPHASE @jcco = @JCCo, @job = @Job, @phase = @Phase, @phasegroup = @PhaseGroup, @msg = @msg OUTPUT
	IF @rcode = 1
	BEGIN
		RETURN 1
	END

	/*1.  Get Phase Cost Type UM from JCCH if Job exists
	   2.  Get JC Job/Phase/Cost Type UM for JCCD columns: UM and Posted UM (required for JCCD)*/
	EXEC @rcode = dbo.bspJCVCOSTTYPE @jcco = @JCCo, @job = @Job, @PhaseGroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType, @override = 'N',
		@um = @JobPhaseCostTypeUM OUTPUT, @msg = @msg OUTPUT
	IF @rcode = 1
	BEGIN
		RETURN 1
	END

	--Get JC Actual Units based HQMU (UM) conversion
	EXEC @rcode = dbo.bspAPLBValJob @jcco = @JCCo, @phasegroup = @PhaseGroup, @job = @Job, @phase = @Phase, @jcctype = @JCCostType,
		@matlgroup = @MatlGroup, @material = @Material, @um = @PostedUM, @units = @PostedUnits, 
		@jcum = @JobPhaseCostTypeUM OUTPUT, @jcunits = @JCActualUnits OUTPUT, @msg = @msg OUTPUT
	IF @rcode=1
	BEGIN
		RETURN 1
	END

	SELECT @VendorGroup = VendorGroup, @Vendor = Vendor 
	FROM dbo.bPOHD 
	WHERE POCo = @POCo AND PO = @PO

	SET @RemainCmtdCost = -(SELECT CASE WHEN UM = 'LS' THEN @GrossAmount ELSE @PostedUnits * CurUnitCost / dbo.vpfECMFactor(CurECM) END FROM dbo.bPOIT WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem)

	SELECT @IsTaxRedirect = 0, @TaxType = TaxType, @TaxGroup = TaxGroup, @TaxCode = TaxCode,
		@RemCmtdTaxAmount = 0, @TaxBasis = ISNULL(@TaxBasis, 0), @TaxAmount = ISNULL(@TaxAmount, 0)
	FROM dbo.vPOItemLine
	WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
	
	--Handle Taxes
	IF @TaxCode IS NOT NULL
	BEGIN
		EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, 
			@valueadd = NULL, @taxrate = NULL, @taxphase = @TaxPhase OUTPUT, @taxjcctype = @TaxCostType OUTPUT, @gstrate = NULL, @crdGLAcct = NULL, 
			@crdRetgGLAcct = NULL, @dbtGLAcct = @dbtGLAcct OUTPUT, @dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, @msg = @msg OUTPUT
		IF @rcode <> 0 RETURN @rcode
	
		SELECT @TaxPhase = ISNULL(@TaxPhase, @Phase), @TaxCostType = ISNULL(@TaxCostType, @JCCostType),
			@IsTaxRedirect = ~dbo.vfIsEqual(@TaxPhase, @Phase) | ~dbo.vfIsEqual(@TaxCostType, @JCCostType)

		--The GST portion of taxes are not included in the tax amount if the GST tax code has an ITC account set.
		SELECT @RemCmtdTaxAmount = @RemainCmtdCost * (TaxRate - CASE WHEN @dbtGLAcct IS NOT NULL THEN GSTRate ELSE 0 END),
			@RemainCmtdCost = @RemainCmtdCost + @RemCmtdTaxAmount
		FROM dbo.vPOItemLine
		WHERE POCo = @POCo AND PO= @PO AND POItem = @POItem AND POItemLine = @POItemLine

		IF @RateBasis = 'S'
		BEGIN
			--If the rate basis is something like standard cost then taxes are not sent to the job.
			SELECT @TaxBasis = 0, @TaxAmount = 0
		END
		ELSE
		BEGIN
			--If the rate basis is actual cost then taxes are included.
			SELECT @TaxAmount = @TaxAmount * @RateMarkup,
				@TaxBasis = @TaxBasis * @RateMarkup
		END
	END

	EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @msg OUTPUT

	IF @GLEntryID = -1 RETURN 1

	INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
	VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @JCCo)

	EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @msg = @msg OUTPUT
		
	IF @JCCostEntryID = -1 RETURN 1
	
	UPDATE dbo.vSMWorkCompletedBatch
	SET CurrentRevenueGLEntryID = @GLEntryID, CurrentJCCostEntryID = @JCCostEntryID
	WHERE SMWorkCompletedID = @SMWorkCompletedID
	
	INSERT dbo.vSMWorkCompletedJCCostEntry (JCCostEntryID, SMWorkCompletedID)
	VALUES (@JCCostEntryID, @SMWorkCompletedID)
	
	--Creating (add) SM Job Cost Distribution record
	SELECT @JCGLCo = GLCo, @GLCostDetailDesc = RTRIM(dbo.vfToString(GLCostDetailDesc))
	FROM dbo.bJCCO
	WHERE JCCo = @JCCo
	
	SELECT @TransDesc = @GLCostDetailDesc,
		@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@Job))),
		@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@Phase))),
		@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@JCCostType))),
		@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'JC'),
		@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@WorkCompletedDescription)))

	SELECT @SMGLCo = GLCo, @SMGLAcct = CurrentRevenueAccount
	FROM dbo.vfSMGetWorkCompletedGL(@SMWorkCompletedID)
	
	---- validate SM Revenue Account
	EXEC @rcode = dbo.bspGLACfPostable @glco = @SMGLCo, @glacct = @SMGLAcct, @chksubtype = 'S', @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	INSERT @GLDistributions
	VALUES (1, @SMGLCo, @SMGLAcct, -@JCActualCost, @TransDesc, 1)

	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, GLInterfaceLevel, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
	SELECT 0 IsReversing, 1 Posted, @GLInterfaceLevel, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 5 LineType, 'R' TransactionType, @BatchCo, @BatchMth, @BatchId, @SMGLCo, @SMGLAcct, -@JCActualCost
	FROM dbo.SMWorkCompleted
		INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE SMWorkCompletedID = @SMWorkCompletedID

	--INTERCOMPANY
	IF (@JCGLCo <> @SMGLCo)
	BEGIN
		-- get interco GL Accounts
		SELECT @ARGLAcct = ARGLAcct, @APGLAcct = APGLAcct
		FROM dbo.bGLIA
		WHERE ARGLCo = @SMGLCo and APGLCo = @JCGLCo
		IF @@rowcount = 0
        BEGIN
             SELECT @msg = 'Intercompany Accounts not setup in GL for these companies!'
   			 RETURN 1
        END

		EXEC @rcode = dbo.bspGLACfPostable @glco = @SMGLCo, @glacct = @ARGLAcct, @chksubtype = 'R', @msg = @msg OUTPUT
		IF @rcode <> 0 RETURN @rcode
		
		EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @APGLAcct, @chksubtype = 'P', @msg = @msg OUTPUT
		IF @rcode <> 0 RETURN @rcode
		
		INSERT @GLDistributions
		VALUES (2, @SMGLCo, @ARGLAcct, @JCActualCost, @TransDesc, 1)

		INSERT @GLDistributions
		VALUES (3, @JCGLCo, @APGLAcct, -@JCActualCost, @TransDesc, 1)
	END

	EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType, @override = 'N', @glacct = @JCGLAcct OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	IF @JCGLAcct IS NULL
	BEGIN
		SET @msg = 'Missing GL Account for JCCo:' + dbo.vfToString(@JCCo) + ' , Job:' + dbo.vfToString(@Job) + ' , Phase:' + dbo.vfToString(@Phase) + ' , CostType:' + dbo.vfToString(@JCCostType) 
		RETURN 1
	END

	--Validate Job Expense Account
	EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @JCGLAcct, @chksubtype = 'J', @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	/* Create the Job Cost Detail Detail record for current complete work id record */
	BEGIN TRY
		IF @IsTaxRedirect = 1
		BEGIN
			SELECT @JCActualCost = @JCActualCost - @TaxAmount, @RemainCmtdCost = @RemainCmtdCost - @RemCmtdTaxAmount
		END
		
		INSERT @GLDistributions
		VALUES (4, @JCGLCo, @JCGLAcct, @JCActualCost, @TransDesc, 1)

		INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
		VALUES (@JCCostEntryID, 1, @JCCo, @Job, @PhaseGroup, @Phase, @JCCostType, @JCActualCost)
	
		INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID, IsReversingEntry, IsTaxRedirect, BatchCo, BatchMth, BatchID, SMCo, SMWorkOrder, SMScope,
			JCCo, Job, Phase, PhaseGroup, CostType, JobPhaseCostTypeUM, [Description], PostedDate,
			POCo, PO, POItem, POItemLine, VendorGroup, Vendor,
			MatlGroup, Material, PostedUM, PECM,
			ActualUnitCost, ActualUnits, ActualCost,
			PostedUnits, PostedUnitCost, PostedECM,
			PostRemCmUnits, RemainCmtdUnits, RemainCmtdCost,
			TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt, RemCmtdTax,
			JCTransType)

		SELECT @SMWorkCompletedID, 0 IsReversingEntry, 0 IsTaxRedirect, @BatchCo, @BatchMth, @BatchId, SMCo, WorkOrder, Scope,
			@JCCo, @Job, @Phase, @PhaseGroup, @JCCostType, @JobPhaseCostTypeUM, [Description], [Date], 
			POCo, PO, POItem, POItemLine, @VendorGroup, @Vendor,
			MatlGroup, Part, UM, 'E' PECM,
			CASE WHEN @JCActualUnits = 0 THEN 0 ELSE @JCActualCost / @JCActualUnits END, @JCActualUnits, @JCActualCost,
			@PostedUnits, CASE WHEN @PostedUnits = 0 THEN 0 ELSE @JCActualCost / @PostedUnits END, 'E' PostedECM,
			-@PostedUnits, -@JCActualUnits, @RemainCmtdCost,
			@TaxType, @TaxGroup, @TaxCode, CASE WHEN @IsTaxRedirect = 1 THEN 0 ELSE @TaxBasis END, CASE WHEN @IsTaxRedirect = 1 THEN 0 ELSE @TaxAmount END, CASE WHEN @IsTaxRedirect = 1 THEN 0 ELSE @RemCmtdTaxAmount END,
			'AP'
		FROM dbo.SMWorkCompletedAllCurrent
		WHERE SMWorkCompletedID = @SMWorkCompletedID
	END TRY
	BEGIN CATCH
		SET @msg = 'Failed to create Job Cost Detail distribution record: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH

	IF @IsTaxRedirect = 1
	BEGIN
		BEGIN TRY
			--If the rate basis is actual cost then taxes are included. Create TaxCode Phase/CostType Redirect Job Cost Detail record and gl entry transaction.
			IF @RateBasis IS NULL OR @RateBasis <> 'S'
			BEGIN
				SELECT @TransDesc = @GLCostDetailDesc,
					@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@Job))),
					@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@TaxPhase))),
					@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@TaxCostType))),
					@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'JC'),
					@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@WorkCompletedDescription)))

				EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @TaxPhase, @costtype = @TaxCostType, @override = 'N', @glacct = @JCGLAcct OUTPUT, @msg = @msg OUTPUT
				IF @rcode <> 0 RETURN @rcode

				---- validate Job Expense Account
				EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @JCGLAcct, @chksubtype = 'J', @msg = @msg OUTPUT
				IF @rcode <> 0 RETURN @rcode

				INSERT @GLDistributions
				VALUES (5, @JCGLCo, @JCGLAcct, @TaxAmount, @TransDesc, 2)
			END
		
			INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
			VALUES (@JCCostEntryID, 2, @JCCo, @Job, @PhaseGroup, @TaxPhase, @TaxCostType, @TaxAmount)

			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,BatchCo, BatchMth, BatchID,	SMCo, SMWorkOrder, SMScope,
				JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate,
				POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
				MatlGroup, Material,
				ActualCost, RemainCmtdCost,
				TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt, RemCmtdTax,
				JCTransType)

			SELECT @SMWorkCompletedID, 0, 1, @BatchCo, @BatchMth, @BatchId, SMCo, WorkOrder, Scope,
				@JCCo, @Job, @TaxPhase, @PhaseGroup, @TaxCostType, [Description], [Date], 
				POCo, PO, POItem, POItemLine, @VendorGroup, @Vendor,
				MatlGroup, Part, 
				@TaxAmount, @RemCmtdTaxAmount,
				@TaxType, @TaxGroup, @TaxCode, @TaxBasis, @TaxAmount, @RemCmtdTaxAmount,
				'AP'
			FROM dbo.SMWorkCompletedAllCurrent
			WHERE SMWorkCompletedID = @SMWorkCompletedID
		END TRY
		BEGIN CATCH
			SET @msg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' +  ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

	--Make sure debits and credits balance
	IF EXISTS(SELECT 1 
				FROM @GLDistributions
				GROUP BY GLCo
				HAVING ISNULL(SUM(Amount), 0) <> 0)
	BEGIN
		SET @msg = 'GL entries dont balance!'
		RETURN 1
	END
	
	INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description], DetailTransGroup)
	SELECT @GLEntryID, Trans, GLCo, GLAccount, Amount, @Date, [Description], DetailTransGroup
	FROM @GLDistributions

	INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
	VALUES (@GLEntryID, 1, @SMWorkCompletedID)
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMJobCostPurchaseDistribution] TO [public]
GO
