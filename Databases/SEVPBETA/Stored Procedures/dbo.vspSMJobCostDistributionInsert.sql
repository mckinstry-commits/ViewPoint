SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:  TRL 
-- Create date: 02/20/12
-- Description:	TK-12747 Used to create a Job Cost Detail transaction for SM Work Orders associated with Job.
--called from vspSMEMUsageBatchValidation and vspSMINBatchValidation
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
-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostDistributionInsert]
	 @SMWorkCompletedID bigint, @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @JCTransType varchar(2) = NULL, @GrossAmount bDollar = NULL, @TaxBasis bDollar = NULL, @TaxAmount bDollar = NULL, @errmsg varchar(255)=NULL output
AS
	
SET NOCOUNT ON;
		
DECLARE @rcode int, @SMCo bCompany, @SMWorkOrder int, @SMScope int,@SMWorkCompletedType int,
					@JCCo bCompany, @Job bJob,@Phase bPhase,@PhaseGroup bGroup, @JCCostType bJCCType, @JobPhaseCostTypeUM bUM, 
					@OldJCCo bCompany,@OldJCMth bMonth, @OldJCTrans bTrans, @OldJCCostTaxTrans bTrans,
					@IsDeleted bit,@InitialCostsCaptured bit, @PostedUM bUM, @ActualUnits bUnits, @PriceTotal bDollar, 
					@Source tinyint, @ActualCost bDollar, @Date bDate, @WorkCompletedDescription varchar(60), @GLEntryID bigint, @BatchSeq int, @JCCostEntryID bigint,
					@TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxPhase bPhase, @TaxCostType bJCCType,@IsTaxRedirect bit, @RemCmtdTaxAmount bDollar,
					@ActualUnitCost bUnitCost, @JCActualUnits bUnits,@MatlGroup bGroup,@Material bMatl,@RemainCmtdCost bDollar,
					 @POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int, @VendorGroup bGroup, @Vendor bVendor,@PostedUnitCost bUnitCost,
					@PostedECM bECM, @Factor int, @JCUM bUM, @APTLKeyID int, @dbtGLAcct bGLAcct

SELECT @VendorGroup=NULL,@Vendor=NULL,@PostedUnitCost=0, @PostedECM='E'

/*Get SM Work Order Info*/			
SELECT @SMCo=SMWorkCompletedAllCurrent.SMCo, @SMWorkOrder=SMWorkCompletedAllCurrent.WorkOrder, @SMScope=SMWorkCompletedAllCurrent.Scope,
			--Get Job Cost info
			@JCCo=SMWorkOrderScope.JCCo, @Job=SMWorkOrderScope.Job, @Phase=SMWorkOrderScope.Phase,	
			@PhaseGroup = SMWorkCompletedAllCurrent.PhaseGroup, @JCCostType=SMWorkCompletedAllCurrent.JCCostType, 
			--Used for change and delete records.  Links SMWorkCompletedID to JCCD detail record
			@OldJCCo=SMWorkCompletedAllCurrent.JCCo,@OldJCMth=SMWorkCompletedAllCurrent.JCMth, @OldJCTrans= SMWorkCompletedAllCurrent.JCCostTrans,
			--Links to JCCD tax code-redirect phase/cost type
			@OldJCCostTaxTrans = SMWorkCompletedAllCurrent.JCCostTaxTrans,
			--Variables used to deterime add, change or delete
			@IsDeleted =SMWorkCompletedAllCurrent.IsDeleted, 
			@InitialCostsCaptured =SMWorkCompletedAllCurrent.InitialCostsCaptured,
			--SMWorkCompleted Type (Equipment, Misc (AP), Labor (PR), Parts (Source=0) Inventory, Parts(Source=1) Purchase Order			
			@SMWorkCompletedType=SMWorkCompletedAllCurrent.[Type],
			--Used to determine if Actual Units Posted.  Posted UM is compared with JC Job/Phase/Cost Types (JCCH)
			@PostedUM=SMWorkCompletedAllCurrent.UM,
			--Actual Units are derived differently between applications
			@ActualUnits=SMWorkCompletedAllCurrent.Quantity,
			@PriceTotal = ISNULL(SMWorkCompletedAllCurrent.PriceTotal,0),
			@MatlGroup = SMWorkCompletedAllCurrent.MatlGroup,@Material = SMWorkCompletedAllCurrent.Part,
			@Source=SMWorkCompletedAllCurrent.[Source], @ActualCost = SMWorkCompletedAllCurrent.ActualCost,
			@Date = [Date],
			@WorkCompletedDescription = SMWorkCompletedAllCurrent.[Description],
			@POCo= SMWorkCompletedAllCurrent.POCo,	@PO=SMWorkCompletedAllCurrent.PONumber,@POItem=SMWorkCompletedAllCurrent.POItem,@POItemLine=SMWorkCompletedAllCurrent.POItemLine,
			@Factor = case SMWorkCompletedAllCurrent.CostECM when 'C' then 100 when 'M' then 1000 else 1 end,
			@APTLKeyID=SMWorkCompletedAllCurrent.APTLKeyID 
FROM dbo.SMWorkCompletedAllCurrent 
INNER JOIN dbo.SMCO ON SMCO.SMCo=SMWorkCompletedAllCurrent.SMCo
INNER JOIN dbo.SMWorkOrderScope ON SMWorkOrderScope.SMCo=SMWorkCompletedAllCurrent.SMCo 
		AND SMWorkOrderScope.WorkOrder=SMWorkCompletedAllCurrent.WorkOrder AND SMWorkOrderScope.Scope=SMWorkCompletedAllCurrent.Scope
WHERE SMWorkCompletedAllCurrent.KeyID=@SMWorkCompletedID
IF @@rowcount = 0
BEGIN
	--Trial run of Inventory fails due to the WorkCompleted not existing
	--After refactoring material lines batch posting, uncomment code below.
	--SELECT @errmsg = 'No SM WorkComplete record'
	--RETURN 1
	RETURN 0
END

--If no Job in SM Work Order or JC Job Master exit procedure
IF NOT EXISTS (SELECT Top 1 1 FROM dbo.JCJM WHERE JCCo=@JCCo AND Job=@Job)
BEGIN
	RETURN 0
END

DECLARE @GLDistributions TABLE (Trans int, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc, DetailTransGroup int NULL)

--Lazy creation of the batch record. EM batch already creates this records.
IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedBatch WHERE SMWorkCompletedID = @SMWorkCompletedID AND BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId)
BEGIN
	SELECT @BatchSeq = ISNULL(MAX(BatchSeq), 0) + 1
	FROM dbo.vSMWorkCompletedBatch
	WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	
	INSERT dbo.vSMWorkCompletedBatch (SMWorkCompletedID, BatchCo, BatchMonth, BatchId, BatchSeq)
	VALUES (@SMWorkCompletedID, @BatchCo, @BatchMth, @BatchId, @BatchSeq)
END

/*Create (change/delete) reversing record in Job Cost Detail to back out old entry
Check for the change/delete trans first  inserts the reversal tran next to the the 
original trans being changed or deleted JCCD insert procedure needs the records 
in order when assigning JC cost transaction numbers.*/

IF @OldJCTrans IS NOT NULL 
BEGIN
	/* Create reversing from Job Cost Detail Detail record */
	BEGIN TRY
	
		INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,BatchCo, BatchMth, BatchID,SMCo,SMWorkOrder,SMScope,
		JCCo,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,[Description],PostedDate,
		EMCo,Equipment,EMGroup,RevCode,
		PRCo,Employee,
		POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
		INCo,MatlGroup,Loc,Material, PostedUM,	PECM,
		ActualUnitCost,ActualUnits,ActualHours,ActualCost,
		PostedUnits,PostedUnitCost,PostedECM,
		TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
		INStkUnitCost,INStkECM,INStkUM,
		PostRemCmUnits,RemainCmtdUnits,RemainCmtdCost,RemCmtdTax,JCTransType) 

		SELECT SMWorkCompletedID,1,0,@BatchCo,@BatchMth,@BatchId,SMCo,SMWorkOrder,SMScope,
		JCCo,Job,Phase,PhaseGroup,CostType,UM,[Description],PostedDate, 
		EMCo,EMEquip,EMGroup,EMRevCode,
		PRCo,Employee,
		APCo,PO,POItem,POItemLine,VendorGroup,Vendor,
		INCo,MatlGroup,Loc,Material,PostedUM,PerECM,
		ISNULL(ActualUnitCost,0),ISNULL(-ActualUnits,0),ISNULL(-ActualHours,0), ISNULL(-ActualCost,0),
		ISNULL(-PostedUnits,0),ISNULL(PostedUnitCost,0),PostedECM,
		TaxType,TaxGroup,TaxCode,ISNULL(-TaxBasis,0),ISNULL(-TaxAmt,0),
		INStdUnitCost,INStdECM,INStdUM,
		-PostRemCmUnits,-RemainCmtdUnits,-RemainCmtdCost,-RemCmtdTax,JCTransType
		FROM dbo.JCCD 
		WHERE JCCo=@OldJCCo AND Mth=@OldJCMth AND CostTrans=@OldJCTrans 
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Failed to create reversing Job Cost Detail distribution record: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	/* Create reversing TaxCode Phase/CostType Redirect Job Cost Detail Detail record */
	IF @OldJCCostTaxTrans IS NOT NULL
	BEGIN
		BEGIN TRY
			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,BatchCo, BatchMth, BatchID,SMCo,SMWorkOrder,SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate,
			EMCo,Equipment,EMGroup,RevCode,
			PRCo,Employee,
			POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material,
			ActualCost, RemainCmtdCost,
			TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
			RemCmtdTax,JCTransType) 

			SELECT SMWorkCompletedID,1,1,@BatchCo,@BatchMth,@BatchId,SMCo,SMWorkOrder,SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate, 
			EMCo,EMEquip,EMGroup,EMRevCode,
			PRCo,Employee,
			APCo,PO,POItem,POItemLine,VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material,
			-ActualCost, -RemainCmtdCost,
			TaxType,TaxGroup,TaxCode,-TaxBasis,-TaxAmt,
			-RemCmtdTax,JCTransType
			FROM dbo.JCCD 
			WHERE JCCo = @OldJCCo AND Mth = @OldJCMth AND CostTrans = @OldJCCostTaxTrans
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

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
		EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @errmsg OUTPUT

		IF @GLEntryID = -1 RETURN 1

		INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
		VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @OldJCCo)
		
		EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @msg = @errmsg OUTPUT
		
		IF @JCCostEntryID = -1 RETURN 1
		
		UPDATE dbo.vSMWorkCompletedBatch
		SET ReversingRevenueGLEntryID = @GLEntryID, ReversingJCCostEntryID = @JCCostEntryID
		WHERE SMWorkCompletedID = @SMWorkCompletedID

		INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
		SELECT @GLEntryID, Trans, GLCo, GLAccount, Amount, @Date, [Description]
		FROM @GLDistributions
	END
END

DECLARE @JCGLCo bCompany, @GLCostDetailDesc varchar(60), @TransDesc varchar(60), @SMGLCo bCompany, @SMGLAcct bGLAcct, @JCGLAcct bGLAcct, @ARGLAcct bGLAcct, @APGLAcct bGLAcct

DELETE @GLDistributions

--Creating (add) SM Job Cost Distribution record
IF @IsDeleted = 0
BEGIN
	SELECT @JCGLCo = GLCo, @GLCostDetailDesc = RTRIM(dbo.vfToString(GLCostDetailDesc))
	FROM dbo.bJCCO
	WHERE JCCo = @JCCo
	
	SELECT @SMGLCo = GLCo, @SMGLAcct = CurrentRevenueAccount
	FROM dbo.vfSMGetWorkCompletedGL(@SMWorkCompletedID)

	-- Validates that the phase is active
	EXEC @rcode = bspJCVPHASE @jcco = @JCCo, @job = @Job, @phase = @Phase, @phasegroup = @PhaseGroup, @msg = @errmsg OUTPUT
	IF @rcode = 1
	BEGIN
		RETURN 1
	END

	/*1.  Get Phase Cost Type UM from JCCH if Job exists
	   2.  Get JC Job/Phase/Cost Type UM for JCCD columns: UM and Posted UM (required for JCCD)*/
	EXEC @rcode = dbo.bspJCVCOSTTYPE @jcco=@JCCo, @job=@Job,@PhaseGroup=@PhaseGroup,@phase=@Phase,@costtype=@JCCostType, @override='N',
							@um=@JobPhaseCostTypeUM OUTPUT, @msg=@errmsg OUTPUT
	IF @rcode = 1
	BEGIN
		RETURN 1
	END

	--Set Equipment UM and Actual Units
	IF @SMWorkCompletedType = 1
		BEGIN
					SELECT @PostedUM = CASE WHEN  ISNULL(a.WorkUnits,0) <> 0 THEN EquipmentRevCodeSetup.WorkUM ELSE EquipmentRevCodeSetup.TimeUM END,
								@ActualUnits =	 ISNULL(a.WorkUnits,0)
					FROM dbo.SMWorkCompletedAllCurrent a
					OUTER APPLY dbo.vfEMEquipmentRevCodeSetup (a.EMCo,a.Equipment,a.EMGroup,a.RevCode)  EquipmentRevCodeSetup
					WHERE a.SMWorkCompletedID = @SMWorkCompletedID 
		END
	--Set Actual Units for AP entries	
	ELSE IF @SMWorkCompletedType = 3
		BEGIN
					IF @JCTransType = 'AP' --Source from AP Transaction Entry
						BEGIN
							DECLARE @APInvDate bDate, @ValueAdd bYN, @TaxRate bRate, @GSTRate bRate, @DebitGLAcct bGLAcct
						
							SELECT 
								@PostedUM = bAPTL.UM,
								@Factor = dbo.vpfECMFactor(bAPTL.ECM),
								@ActualUnits = bAPTL.Units,
								@TaxType = bAPTL.TaxType,
								@TaxGroup = bAPTL.TaxGroup,
								@TaxCode = bAPTL.TaxCode,
								@TaxBasis = bAPTL.TaxBasis,
								@TaxAmount = bAPTL.TaxAmt,
								@APInvDate = bAPTH.InvDate
							FROM dbo.bAPTL
								INNER JOIN dbo.bAPTH ON bAPTL.APCo = bAPTH.APCo AND bAPTL.Mth = bAPTH.Mth AND bAPTL.APTrans = bAPTH.APTrans
							WHERE bAPTL.KeyID = @APTLKeyID

							--Really the tax amount from AP should be captured at batch validation
							--but since it would be difficult to capture that value here the tax amount
							--will be recalculated for VAT tax handling. At some point AP should be refactored
							--to handle SM Job integration during batch validation.
							EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @APInvDate,
								@valueadd = @ValueAdd OUTPUT, @taxrate = @TaxRate OUTPUT, @gstrate = @GSTRate OUTPUT,
								@crdGLAcct = NULL, @crdRetgGLAcct = NULL, @dbtGLAcct = @DebitGLAcct OUTPUT, @dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, @msg = @errmsg OUTPUT
							
							--Calculate the non GST tax amount unless the GST tax setup doesn't have the DebitGL account setup
							IF @ValueAdd = 'Y' AND @DebitGLAcct IS NOT NULL
							BEGIN
								--Take the GST portion of the tax out of the full tax amount
								SELECT @TaxAmount = @TaxAmount - ((@TaxAmount * @GSTRate) / @TaxRate)
							END
						END
					ELSE
						--JC TransType='MI' SMWorkCompleted Misc entry
						BEGIN
								SELECT @PostedUM='LS', @ActualUnits=0
						END
		END
	--Set Parts/Inventory UM and Actual Units
	ELSE IF @SMWorkCompletedType = 5
	BEGIN
		SELECT  @ActualUnits = ISNULL(ActualUnits,0)
		FROM dbo.SMWorkCompletedAllCurrent
		WHERE SMWorkCompletedID = @SMWorkCompletedID

		SELECT @TaxType = TaxType,
			@TaxGroup = TaxGroup,
			@TaxCode = TaxCode
		FROM dbo.vPOItemLine
		WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
	END

	IF @ActualUnits<> 0
	BEGIN
		--SM Work Completed Equipment records doesn't post a PostedUnitCost
		IF @SMWorkCompletedType <> 1 
		BEGIN
			SELECT @PostedUnitCost = @PriceTotal/@ActualUnits
		END
	END
	
	--JC Actual Units updates to RemCmtdUnits and ActualUnits when Posting UM match JCCH.UM
	--ActualUnitCost is calculated based on JC Actual Units
	SELECT  @JCActualUnits = 0,@ActualUnitCost=0
	SELECT @VendorGroup=VendorGroup,@Vendor=Vendor FROM dbo.POHD WHERE POCo=@POCo AND PO=@PO 
	--Get JC Actual Units based HQMU (UM) conversion
	EXEC @rcode = bspAPLBValJob @jcco=@JCCo, @phasegroup=@PhaseGroup, @job=@Job, @phase=@Phase, 
	@jcctype=@JCCostType, @matlgroup=@MatlGroup, @material=@Material, @um=@PostedUM, @units=@ActualUnits, 
	@jcum=@JobPhaseCostTypeUM OUTPUT, @jcunits =@JCActualUnits OUTPUT, @msg=@errmsg OUTPUT
	IF @rcode=1
	BEGIN
		RETURN 1
	END
	
	IF EXISTS (SELECT TOP 1 1 FROM dbo.HQMU WHERE MatlGroup=@MatlGroup AND Material=@Material AND UM=@JobPhaseCostTypeUM)
	BEGIN
		SELECT @PostedECM=CostECM FROM dbo.HQMU WHERE MatlGroup=@MatlGroup AND Material=@Material AND UM=@JobPhaseCostTypeUM
	END

	IF @JCActualUnits <> 0
	BEGIN
			--SM Work Completed Equipment records doesn't post a ActualUnitCost
			IF @SMWorkCompletedType <> 1 
			BEGIN
				SELECT @ActualUnitCost=@PriceTotal/@JCActualUnits
			END
	END

	IF @SMWorkCompletedType = 5
	BEGIN
		IF @PostedUM = 'LS' 
		BEGIN
			SELECT @RemainCmtdCost = -@GrossAmount
		END
		ELSE
		BEGIN
			IF @PostedUM = @JobPhaseCostTypeUM 
			BEGIN
				SET @RemainCmtdCost = -(SELECT @JCActualUnits * CurUnitCost / @Factor  FROM dbo.POIT WHERE POCo=@POCo AND PO=@PO AND POItem=@POItem)
			END
			ELSE
			BEGIN
				SET @RemainCmtdCost = -(SELECT @ActualUnits * CurUnitCost / @Factor  FROM dbo.POIT WHERE POCo=@POCo AND PO=@PO AND POItem=@POItem)
			END
		END
	END
	
	--Prevents JCCD record being created when no AP Trans exist
	--Prevents JCCD record from being created when deleting AP Invoice Trans
	IF @SMWorkCompletedType = 5 AND @ActualCost = 0
	BEGIN
		RETURN 0
	END

	IF @JCTransType NOT IN ('AP','MI','IN','EM','PR')
	BEGIN
		   SELECT @errmsg = 'Invalid JC Transaction Type!'
   		   RETURN 1
	END
	
	SET @IsTaxRedirect = 0
	
	--Check to see if the TaxCode has a Phase, JC Cost Type redirect values
	IF @TaxCode IS NOT NULL
	BEGIN
		EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, 
			@valueadd = NULL, @taxrate = NULL, @taxphase = @TaxPhase OUTPUT, @taxjcctype = @TaxCostType OUTPUT, @gstrate = NULL, @crdGLAcct = NULL, 
			@crdRetgGLAcct = NULL, @dbtGLAcct = @dbtGLAcct OUTPUT, @dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, @msg = @errmsg OUTPUT
		IF @rcode <> 0 RETURN @rcode
	
		SELECT @TaxPhase = ISNULL(@TaxPhase, @Phase), @TaxCostType = ISNULL(@TaxCostType, @JCCostType),
			@IsTaxRedirect = ~dbo.vfIsEqual(@TaxPhase, @Phase) | ~dbo.vfIsEqual(@TaxCostType, @JCCostType),
			@TaxAmount = @TaxAmount * CASE WHEN @ActualCost = 0 THEN 0 ELSE @PriceTotal / @ActualCost END,
			@TaxBasis = @TaxBasis * CASE WHEN @ActualCost = 0 THEN 0 ELSE @PriceTotal / @ActualCost END
			
		IF @SMWorkCompletedType = 5
		BEGIN
			--The GST portion of taxes are not included in the tax amount if the GST tax code has an ITC account set.
			SELECT @RemCmtdTaxAmount = @RemainCmtdCost * (TaxRate - CASE WHEN @dbtGLAcct IS NOT NULL THEN GSTRate ELSE 0 END),
				@RemainCmtdCost = @RemainCmtdCost + @RemCmtdTaxAmount
			FROM dbo.vPOItemLine
			WHERE POCo = @POCo AND PO= @PO AND POItem = @POItem AND POItemLine = @POItemLine
		END
	END
	
	EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @errmsg OUTPUT

	IF @GLEntryID = -1 RETURN 1

	INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
	VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @JCCo)

	EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @msg = @errmsg OUTPUT
		
	IF @JCCostEntryID = -1 RETURN 1
	
	UPDATE dbo.vSMWorkCompletedBatch
	SET CurrentRevenueGLEntryID = @GLEntryID, CurrentJCCostEntryID = @JCCostEntryID
	WHERE SMWorkCompletedID = @SMWorkCompletedID
	
	INSERT dbo.vSMWorkCompletedJCCostEntry (JCCostEntryID, SMWorkCompletedID)
	VALUES (@JCCostEntryID, @SMWorkCompletedID)
	
	SELECT @TransDesc = @GLCostDetailDesc,
		@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@Job))),
		@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@Phase))),
		@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@JCCostType))),
		@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'JC'),
		@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@WorkCompletedDescription)))
	
	---- validate SM Revenue Account
	EXEC @rcode = dbo.bspGLACfPostable @glco = @SMGLCo, @glacct = @SMGLAcct, @chksubtype = 'S', @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	INSERT @GLDistributions
	VALUES (1, @SMGLCo, @SMGLAcct, -@PriceTotal, @TransDesc, 1)

	--INTERCOMPANY
	IF (@JCGLCo <> @SMGLCo)
	BEGIN
		-- get interco GL Accounts
		SELECT @ARGLAcct = ARGLAcct, @APGLAcct = APGLAcct
		FROM dbo.bGLIA
		WHERE ARGLCo = @SMGLCo and APGLCo = @JCGLCo
		IF @@rowcount = 0
        BEGIN
             SELECT @errmsg = 'Intercompany Accounts not setup in GL for these companies!'
   			 RETURN 1
        END

		EXEC @rcode = dbo.bspGLACfPostable @glco = @SMGLCo, @glacct = @ARGLAcct, @chksubtype = 'R', @msg = @errmsg OUTPUT
		IF @rcode <> 0 RETURN @rcode
		
		EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @APGLAcct, @chksubtype = 'P', @msg = @errmsg OUTPUT
		IF @rcode <> 0 RETURN @rcode
		
		INSERT @GLDistributions
		VALUES (2, @SMGLCo, @ARGLAcct, @PriceTotal, @TransDesc, 1)

		INSERT @GLDistributions
		VALUES (3, @JCGLCo, @APGLAcct, -@PriceTotal, @TransDesc, 1)
	END

	EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType, @override = 'N', @glacct = @JCGLAcct OUTPUT, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	IF @JCGLAcct IS NULL
	BEGIN
		SET @errmsg = 'Missing GL Account for JCCo:' + dbo.vfToString(@JCCo) + ' , Job:' + dbo.vfToString(@Job) + ' , Phase:' + dbo.vfToString(@Phase) + ' , CostType:' + dbo.vfToString(@JCCostType) 
		RETURN 1
	END

	---- validate Job Expense Account
	EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @JCGLAcct, @chksubtype = 'J', @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SELECT @RemainCmtdCost = ISNULL(@RemainCmtdCost, 0), @RemCmtdTaxAmount = ISNULL(@RemCmtdTaxAmount, 0), @TaxBasis = ISNULL(@TaxBasis, 0), @TaxAmount = ISNULL(@TaxAmount, 0)

	--From here on out the price total and committed cost will exclude the tax if there is a tax redirect
	IF @IsTaxRedirect = 1
	BEGIN
		SELECT @PriceTotal = @PriceTotal - @TaxAmount, @RemainCmtdCost = @RemainCmtdCost - @RemCmtdTaxAmount
	END

	INSERT @GLDistributions
	VALUES (4, @JCGLCo, @JCGLAcct, @PriceTotal, @TransDesc, 1)

	/* Create TaxCode Phase/CostType Redirect Job Cost Detail record and gl entry transaction */
	IF @IsTaxRedirect = 1
	BEGIN
		SELECT @TransDesc = @GLCostDetailDesc,
			@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@Job))),
			@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@TaxPhase))),
			@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@TaxCostType))),
			@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'JC'),
			@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@WorkCompletedDescription)))

		EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @TaxPhase, @costtype = @TaxCostType, @override = 'N', @glacct = @JCGLAcct OUTPUT, @msg = @errmsg OUTPUT
		IF @rcode <> 0 RETURN @rcode

		---- validate Job Expense Account
		EXEC @rcode = dbo.bspGLACfPostable @glco = @JCGLCo, @glacct = @JCGLAcct, @chksubtype = 'J', @msg = @errmsg OUTPUT
		IF @rcode <> 0 RETURN @rcode

		INSERT @GLDistributions
		VALUES (5, @JCGLCo, @JCGLAcct, @TaxAmount, @TransDesc, 2)
		
		BEGIN TRY
			INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
			VALUES (@JCCostEntryID, 2, @JCCo, @Job, @PhaseGroup, @TaxPhase, @TaxCostType, @TaxAmount)
		
			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,BatchCo, BatchMth, BatchID,	SMCo, SMWorkOrder, SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate,
			EMCo,Equipment,EMGroup,RevCode,
			PRCo,Employee,
			POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
			INCo, MatlGroup, Loc, Material,
			ActualCost, RemainCmtdCost,
			TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt, RemCmtdTax,
			JCTransType)

			SELECT @SMWorkCompletedID,0,1,@BatchCo,@BatchMth,@BatchId,a.SMCo,a.WorkOrder,a.Scope,
			@JCCo,@Job,@TaxPhase,@PhaseGroup, @TaxCostType,	a.[Description],a.[Date], 
			a.EMCo,a.Equipment,	a.EMGroup,a.RevCode, 
			SMTechnician.PRCo,SMTechnician.Employee,
			a.POCo,a.PONumber,a.POItem,a.POItemLine,@VendorGroup,@Vendor,
			a.INCo,	a.MatlGroup, a.INLocation, a.Part, 
			@TaxAmount, @RemCmtdTaxAmount,
			@TaxType, @TaxGroup, @TaxCode, @TaxBasis, @TaxAmount, @RemCmtdTaxAmount,
			@JCTransType
			FROM dbo.SMWorkCompletedAllCurrent a
				LEFT JOIN dbo.SMTechnician ON SMTechnician.SMCo=a.SMCo AND SMTechnician.Technician=a.Technician
			WHERE a.SMWorkCompletedID = @SMWorkCompletedID 
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' +  ERROR_MESSAGE()
			RETURN 1
		END CATCH

		--Set the tax amounts to 0 so taxes are also included in the actual cost detail line
		SELECT @RemCmtdTaxAmount = 0, @TaxBasis = 0, @TaxAmount = 0
	END

	--Make sure debits and credits balance
	IF EXISTS(SELECT 1 
				FROM @GLDistributions
				GROUP BY GLCo
				HAVING ISNULL(SUM(Amount), 0) <> 0)
	BEGIN
		SET @errmsg = 'GL entries dont balance!'
		RETURN 1
	END
	
	INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description], DetailTransGroup)
	SELECT @GLEntryID, Trans, GLCo, GLAccount, Amount, @Date, [Description], DetailTransGroup
	FROM @GLDistributions

	INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
	VALUES (@GLEntryID, 1, @SMWorkCompletedID)

	/* Create the Job Cost Detail Detail record for current complete work id record */
	BEGIN TRY
		INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
		VALUES (@JCCostEntryID, 1, @JCCo, @Job, @PhaseGroup, @Phase, @JCCostType, @PriceTotal)
	
		INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,BatchCo,	BatchMth, BatchID,	SMCo,SMWorkOrder,SMScope,
		JCCo,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,[Description],PostedDate,
		EMCo,Equipment,EMGroup,RevCode,
		PRCo,Employee,
		POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
		INCo,MatlGroup,Loc,Material, PostedUM,	PECM,
		ActualUnitCost,ActualUnits,ActualHours,ActualCost,
		PostedUnits,	PostedUnitCost,PostedECM,
		INStkUnitCost,INStkECM,INStkUM,
		TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
		PostRemCmUnits,RemainCmtdUnits,RemainCmtdCost,RemCmtdTax,JCTransType)

		SELECT @SMWorkCompletedID,0,0,@BatchCo,@BatchMth,@BatchId,a.SMCo,a.WorkOrder,a.Scope,
		@JCCo,@Job,@Phase,@PhaseGroup, @JCCostType, @JobPhaseCostTypeUM,	a.[Description],a.[Date], 
		a.EMCo,a.Equipment,	a.EMGroup,a.RevCode, 
		SMTechnician.PRCo,SMTechnician.Employee,
		a.POCo,a.PONumber,a.POItem,a.POItemLine,@VendorGroup,@Vendor,
		a.INCo,	a.MatlGroup,	a.INLocation,	a.Part, 
		/*PostedUM*/ CASE WHEN @JCTransType = 'MI' THEN 'LS' 
									  ELSE ISNULL(@PostedUM,@JobPhaseCostTypeUM) END , 
		/*PECM*/ CASE WHEN @JCTransType = 'MI' OR @JCTransType = 'AP' THEN 'E'
								WHEN @SMWorkCompletedType = 1 THEN 'E'  
								ELSE ISNULL(@PostedECM,a.PriceECM) END,	
		/*ActualUnitCost*/ ISNULL(@ActualUnitCost,0),/*ActualUnits*/ISNULL(@JCActualUnits,0),/*ActualHours*/ISNULL(a.TimeUnits,0),	/*ActualCost*/@PriceTotal,	/*PostedUnits*/ISNULL(@ActualUnits,0),	
		/*PostedUnitCost*/CASE WHEN a.Source=1 THEN ISNULL(@PostedUnitCost,0)  
											WHEN @SMWorkCompletedType = 1 OR @PostedUM='LS' THEN 0 
											ELSE a.CostRate END,
		/*PostedECM*/CASE  WHEN @JCTransType = 'MI' OR @JCTransType = 'AP'  THEN 'E'
										WHEN @SMWorkCompletedType = 1 THEN 'E'  
										ELSE ISNULL(a.CostECM,@PostedECM) END,
		INMT.StdCost,INMT.StdECM, HQMT.StdUM,				
		@TaxType, @TaxGroup, @TaxCode, @TaxBasis, @TaxAmount,
		/*PostRemCmUnits*/CASE WHEN ISNULL(a.PONumber,'') <> '' THEN ISNULL(-@ActualUnits,0) ELSE 0 END,
		/*RemainCmtdUnits*/CASE WHEN ISNULL(a.PONumber,'') <> '' THEN ISNULL(-@JCActualUnits,0) ELSE 0 END,
		@RemainCmtdCost,
		@RemCmtdTaxAmount,
		@JCTransType
		FROM dbo.SMWorkCompletedAllCurrent a
		LEFT JOIN dbo.SMTechnician ON SMTechnician.SMCo=a.SMCo AND SMTechnician.Technician=a.Technician
		LEFT JOIN dbo.INMT ON INMT.INCo=a.INCo AND INMT.Loc=a.INLocation AND INMT.MatlGroup=a.MatlGroup AND INMT.Material=a.Part
		LEFT JOIN dbo.HQMT ON HQMT.MatlGroup=a.MatlGroup AND HQMT.Material=a.Part 
		WHERE a.SMWorkCompletedID = @SMWorkCompletedID 
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Failed to create Job Cost Detail distribution record: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMJobCostDistributionInsert] TO [public]
GO
