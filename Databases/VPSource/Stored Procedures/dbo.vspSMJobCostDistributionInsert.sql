
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
--						JVH 4/3/13 TFS-38853 Updated to handle changes to vSMJobCostDistribution
-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostDistributionInsert]
	 @SMWorkCompletedID bigint, @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @BatchSeq int, @Line smallint = NULL, @JCTransType varchar(2), @errmsg varchar(255) = NULL output
AS
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @rcode int, @SMCo bCompany, @SMWorkOrder int, @SMScope int,@SMWorkCompletedType int,
						@JCCo bCompany, @Job bJob,@Phase bPhase,@PhaseGroup bGroup, @JCCostType bJCCType, @JobPhaseCostTypeUM bUM, 
						@OldJCCo bCompany,@OldJCMth bMonth, @OldJCTrans bTrans, @OldJCCostTaxTrans bTrans,
						@IsDeleted bit,@InitialCostsCaptured bit, @PostedUM bUM, @ActualUnits bUnits, @PriceTotal bDollar, 
						@Source tinyint, @ActualCost bDollar, @Date bDate, @WorkCompletedDescription varchar(60), @GLEntryID bigint, @JCCostEntryID bigint,
						@TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxPhase bPhase, @TaxCostType bJCCType,@IsTaxRedirect bit,
						@ActualUnitCost bUnitCost, @JCActualUnits bUnits,@MatlGroup bGroup,@Material bMatl,
						@VendorGroup bGroup, @Vendor bVendor,@PostedUnitCost bUnitCost,
						@PostedECM bECM, @JCUM bUM, @APTLKeyID int, @dbtGLAcct bGLAcct, @TaxBasis bDollar, @TaxAmount bDollar

	SELECT @PostedUnitCost=0, @PostedECM='E'

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

	--Lazy creation of the batch record. EM batch already creates this records.
	IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedBatch WHERE SMWorkCompletedID = @SMWorkCompletedID AND BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId)
	BEGIN
		INSERT dbo.vSMWorkCompletedBatch (SMWorkCompletedID, BatchCo, BatchMonth, BatchId, BatchSeq)
		SELECT @SMWorkCompletedID, @BatchCo, @BatchMth, @BatchId, ISNULL(MAX(BatchSeq), 0) + 1
		FROM dbo.vSMWorkCompletedBatch
		WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	END

	/*Create (change/delete) reversing record in Job Cost Detail to back out old entry
	Check for the change/delete trans first  inserts the reversal tran next to the the 
	original trans being changed or deleted JCCD insert procedure needs the records 
	in order when assigning JC cost transaction numbers.*/

	IF @OldJCTrans IS NOT NULL 
	BEGIN
		/* Create reversing from Job Cost Detail Detail record */
		BEGIN TRY
	
			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect, BatchCo, BatchMth, BatchID, BatchSeq, Line,
			SMCo, SMWorkOrder, SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,[Description],PostedDate,
			EMCo,Equipment,EMGroup,RevCode,
			PRCo,Employee,
			VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material, PostedUM,	PECM,
			ActualUnitCost,ActualUnits,ActualHours,ActualCost,
			PostedUnits,PostedUnitCost,PostedECM,
			TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
			INStkUnitCost,INStkECM,INStkUM,
			JCTransType, OffsetGLCo, OffsetGLAcct) 

			SELECT SMWorkCompletedID,1,0,@BatchCo, @BatchMth, @BatchId, @BatchSeq, @Line,
			SMCo, SMWorkOrder, SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,UM,[Description],PostedDate, 
			EMCo,EMEquip,EMGroup,EMRevCode,
			PRCo,Employee,
			VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material,PostedUM,PerECM,
			ISNULL(ActualUnitCost,0),ISNULL(-ActualUnits,0),ISNULL(-ActualHours,0), ISNULL(-ActualCost,0),
			ISNULL(-PostedUnits,0),ISNULL(PostedUnitCost,0),PostedECM,
			TaxType,TaxGroup,TaxCode,ISNULL(-TaxBasis,0),ISNULL(-TaxAmt,0),
			INStdUnitCost,INStdECM,INStdUM,
			JCTransType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount
			FROM dbo.JCCD 
				CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompletedID)
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
				INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect, BatchCo, BatchMth, BatchID, BatchSeq, Line,
				SMCo, SMWorkOrder, SMScope,
				JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate,
				EMCo,Equipment,EMGroup,RevCode,
				PRCo,Employee,
				VendorGroup,Vendor,
				INCo,MatlGroup,Loc,Material,
				ActualCost, RemainCmtdCost,
				TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
				JCTransType, OffsetGLCo, OffsetGLAcct) 

				SELECT SMWorkCompletedID,1,1,@BatchCo, @BatchMth, @BatchId, @BatchSeq, @Line,
				SMCo, SMWorkOrder, SMScope,
				JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate, 
				EMCo,EMEquip,EMGroup,EMRevCode,
				PRCo,Employee,
				VendorGroup,Vendor,
				INCo,MatlGroup,Loc,Material,
				-ActualCost, -RemainCmtdCost,
				TaxType,TaxGroup,TaxCode,-TaxBasis,-TaxAmt,
				JCTransType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount
				FROM dbo.JCCD 
					CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompletedID)
				WHERE JCCo = @OldJCCo AND Mth = @OldJCMth AND CostTrans = @OldJCCostTaxTrans
			END TRY
			BEGIN CATCH
				SET @errmsg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' + ERROR_MESSAGE()
				RETURN 1
			END CATCH
		END
	END

	--Creating (add) SM Job Cost Distribution record
	IF @IsDeleted = 0
	BEGIN
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
									@ActualUnits = bAPTL.Units,
									@TaxType = bAPTL.TaxType,
									@TaxGroup = bAPTL.TaxGroup,
									@TaxCode = bAPTL.TaxCode,
									@TaxBasis = bAPTL.TaxBasis,
									@TaxAmount = bAPTL.TaxAmt,
									@APInvDate = bAPTH.InvDate,
									@VendorGroup = bAPTH.VendorGroup,
									@Vendor = bAPTH.Vendor,
									@MatlGroup = bAPTL.MatlGroup,
									@Material = bAPTL.Material
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
		END

		EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @msg = @errmsg OUTPUT
		
		IF @JCCostEntryID = -1 RETURN 1
	
		UPDATE dbo.vSMWorkCompletedBatch
		SET CurrentJCCostEntryID = @JCCostEntryID
		WHERE SMWorkCompletedID = @SMWorkCompletedID
	
		INSERT dbo.vSMWorkCompletedJCCostEntry (JCCostEntryID, SMWorkCompletedID)
		VALUES (@JCCostEntryID, @SMWorkCompletedID)

		SELECT @TaxBasis = ISNULL(@TaxBasis, 0), @TaxAmount = ISNULL(@TaxAmount, 0)

		--From here on out the price total and committed cost will exclude the tax if there is a tax redirect
		IF @IsTaxRedirect = 1
		BEGIN
			SELECT @PriceTotal = @PriceTotal - @TaxAmount
		END

		/* Create TaxCode Phase/CostType Redirect Job Cost Detail record and gl entry transaction */
		IF @IsTaxRedirect = 1
		BEGIN
			BEGIN TRY
				INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
				VALUES (@JCCostEntryID, 2, @JCCo, @Job, @PhaseGroup, @TaxPhase, @TaxCostType, @TaxAmount)
		
				INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect, BatchCo, BatchMth, BatchID, BatchSeq, Line,
				SMCo, SMWorkOrder, SMScope,
				JCCo,Job,Phase,PhaseGroup,CostType,[Description],PostedDate,
				EMCo,Equipment,EMGroup,RevCode,
				PRCo,Employee,
				VendorGroup,Vendor,
				INCo, Loc,
				MatlGroup, Material,
				ActualCost,
				TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
				JCTransType, OffsetGLCo, OffsetGLAcct)

				SELECT @SMWorkCompletedID,0,1,@BatchCo, @BatchMth, @BatchId, @BatchSeq, @Line,
				a.SMCo, a.WorkOrder, a.Scope,
				@JCCo,@Job,@TaxPhase,@PhaseGroup, @TaxCostType,	a.[Description],a.[Date], 
				a.EMCo,a.Equipment,	a.EMGroup,a.RevCode, 
				SMTechnician.PRCo,SMTechnician.Employee,
				@VendorGroup,@Vendor,
				a.INCo, a.INLocation,
				@MatlGroup, @Material,
				@TaxAmount,
				@TaxType, @TaxGroup, @TaxCode, @TaxBasis, @TaxAmount,
				@JCTransType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount
				FROM dbo.SMWorkCompletedAllCurrent a
					CROSS APPLY dbo.vfSMGetWorkCompletedGL(a.SMWorkCompletedID)
					LEFT JOIN dbo.SMTechnician ON SMTechnician.SMCo=a.SMCo AND SMTechnician.Technician=a.Technician
				WHERE a.SMWorkCompletedID = @SMWorkCompletedID 
			END TRY
			BEGIN CATCH
				SET @errmsg = 'Failed to create reversing Job Cost Detail Tax Code Phase redirect distribution record: ' +  ERROR_MESSAGE()
				RETURN 1
			END CATCH

			--Set the tax amounts to 0 so taxes are also included in the actual cost detail line
			SELECT @TaxBasis = 0, @TaxAmount = 0
		END

		/* Create the Job Cost Detail Detail record for current complete work id record */
		BEGIN TRY
			INSERT dbo.vJCCostEntryTransaction (JCCostEntryID, JCCostTransaction, JCCo, Job, PhaseGroup, Phase, CostType, ActualCost)
			VALUES (@JCCostEntryID, 1, @JCCo, @Job, @PhaseGroup, @Phase, @JCCostType, @PriceTotal)
	
			INSERT dbo.vSMJobCostDistribution (SMWorkCompletedID,IsReversingEntry,IsTaxRedirect, BatchCo, BatchMth, BatchID, BatchSeq, Line,
			SMCo, SMWorkOrder, SMScope,
			JCCo,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,[Description],PostedDate,
			EMCo,Equipment,EMGroup,RevCode,
			PRCo,Employee,
			VendorGroup, Vendor,
			INCo, Loc,
			MatlGroup, Material,
			PostedUM, PECM,
			ActualUnitCost,ActualUnits,ActualHours,ActualCost,
			PostedUnits, PostedUnitCost, PostedECM,
			INStkUnitCost,INStkECM,INStkUM,
			TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
			JCTransType, OffsetGLCo, OffsetGLAcct)

			SELECT @SMWorkCompletedID,0,0,@BatchCo, @BatchMth, @BatchId, @BatchSeq, @Line,
			a.SMCo, a.WorkOrder, a.Scope,
			@JCCo,@Job,@Phase,@PhaseGroup, @JCCostType, @JobPhaseCostTypeUM, a.[Description], a.[Date], 
			a.EMCo,a.Equipment,	a.EMGroup,a.RevCode, 
			SMTechnician.PRCo,SMTechnician.Employee,
			@VendorGroup,@Vendor,
			a.INCo, a.INLocation,
			@MatlGroup, @Material,
			/*PostedUM*/ CASE WHEN @JCTransType = 'MI' THEN 'LS' 
										  ELSE ISNULL(@PostedUM,@JobPhaseCostTypeUM) END , 
			/*PECM*/ CASE WHEN @JCTransType = 'MI' OR @JCTransType = 'AP' THEN 'E'
									WHEN @SMWorkCompletedType = 1 THEN 'E'  
									ELSE ISNULL(@PostedECM,a.PriceECM) END,	
			/*ActualUnitCost*/ ISNULL(@ActualUnitCost,0),/*ActualUnits*/ISNULL(@JCActualUnits,0),/*ActualHours*/ISNULL(a.TimeUnits,0),	/*ActualCost*/@PriceTotal,	/*PostedUnits*/ISNULL(@ActualUnits,0),	
			/*PostedUnitCost*/CASE WHEN @SMWorkCompletedType = 1 OR @PostedUM='LS' THEN 0 ELSE a.CostRate END,
			/*PostedECM*/CASE  WHEN @JCTransType = 'MI' OR @JCTransType = 'AP'  THEN 'E'
											WHEN @SMWorkCompletedType = 1 THEN 'E'  
											ELSE ISNULL(a.CostECM,@PostedECM) END,
			INMT.StdCost,INMT.StdECM, HQMT.StdUM,
			@TaxType, @TaxGroup, @TaxCode, @TaxBasis, @TaxAmount,
			@JCTransType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount
			FROM dbo.SMWorkCompletedAllCurrent a
				CROSS APPLY dbo.vfSMGetWorkCompletedGL(a.SMWorkCompletedID)
				LEFT JOIN dbo.SMTechnician ON SMTechnician.SMCo=a.SMCo AND SMTechnician.Technician=a.Technician
				LEFT JOIN dbo.INMT ON INMT.INCo=a.INCo AND INMT.Loc=a.INLocation AND INMT.MatlGroup = @MatlGroup AND INMT.Material = @Material
				LEFT JOIN dbo.HQMT ON HQMT.MatlGroup = @MatlGroup AND HQMT.Material = @Material
			WHERE a.SMWorkCompletedID = @SMWorkCompletedID 
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Failed to create Job Cost Detail distribution record: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

	DECLARE @GLDistributions TABLE (KeyId int IDENTITY(1,1), GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc, DetailTransGroup int, SubType char(1), IsReversing bit)

	DECLARE @JCGLCo bCompany, @JCGLAcct bGLAcct, @ARGLAcct bGLAcct, @APGLAcct bGLAcct, @TransDesc varchar(60), @DetailTransGroup int, @OffsetGLCo bCompany, @OffsetGLAcct bGLAcct, @Description bItemDesc, @IsReversing bit

	SET @DetailTransGroup = 1
		
	--Build the gl for the job cost detail
	--DetailTransGroup 1 is the current normal detail, 2 is the current tax redirect, 3 reversing normal detail, 4 is the reversing tax redirect
	--Creating the gl should eventually use the vGLDistribution table once code has been modified to handle SM and JC WIP differently.
	WHILE (@DetailTransGroup <= 4)
	BEGIN
		SELECT @OffsetGLCo = OffsetGLCo, @OffsetGLAcct = OffsetGLAcct, @JCCo = JCCo, @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase, @JCCostType = CostType, @ActualCost = ActualCost, @Description = [Description], @IsReversing = IsReversingEntry
		FROM dbo.vSMJobCostDistribution
		WHERE SMWorkCompletedID = @SMWorkCompletedID AND 
			IsReversingEntry = CASE @DetailTransGroup WHEN 1 THEN 0 WHEN 2 THEN 0 WHEN 3 THEN 1 WHEN 4 THEN 1 END AND 
			IsTaxRedirect = CASE @DetailTransGroup WHEN 1 THEN 0 WHEN 2 THEN 1 WHEN 3 THEN 0 WHEN 4 THEN 1 END

		IF @@ROWCOUNT = 1
		BEGIN
			SELECT @JCGLCo = GLCo, @TransDesc = RTRIM(dbo.vfToString(GLCostDetailDesc))
			FROM dbo.bJCCO
			WHERE JCCo = @JCCo

			SELECT @TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@Job))),
				@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@Phase))),
				@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@JCCostType))),
				@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'JC'),
				@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@Description)))

			INSERT @GLDistributions (GLCo, GLAccount, Amount, [Description], DetailTransGroup, SubType, IsReversing)
			VALUES (@OffsetGLCo, @OffsetGLAcct, -@ActualCost, @TransDesc, @DetailTransGroup, 'S', @IsReversing)

			EXEC @rcode = dbo.bspJCCAGlacctDflt @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType, @override = 'N', @glacct = @JCGLAcct OUTPUT, @msg = @errmsg OUTPUT
			IF @rcode <> 0 RETURN @rcode

			IF @JCGLAcct IS NULL
			BEGIN
				SET @errmsg = 'Missing GL Account for JCCo:' + dbo.vfToString(@JCCo) + ' , Job:' + dbo.vfToString(@Job) + ' , Phase:' + dbo.vfToString(@Phase) + ' , CostType:' + dbo.vfToString(@JCCostType) 
				RETURN 1
			END

			INSERT @GLDistributions (GLCo, GLAccount, Amount, [Description], DetailTransGroup, SubType, IsReversing)
			VALUES (@JCGLCo, @JCGLAcct, @ActualCost, @TransDesc, @DetailTransGroup, 'J', @IsReversing)

			IF (@JCGLCo <> @OffsetGLCo)
			BEGIN
				-- get interco GL Accounts
				SELECT @ARGLAcct = ARGLAcct, @APGLAcct = APGLAcct
				FROM dbo.bGLIA
				WHERE ARGLCo = @OffsetGLCo and APGLCo = @JCGLCo
				IF @@ROWCOUNT = 0
				BEGIN
					SELECT @errmsg = 'Intercompany Accounts not setup in GL for these companies!'
   					RETURN 1
				END

				INSERT @GLDistributions (GLCo, GLAccount, Amount, [Description], DetailTransGroup, SubType, IsReversing)
				VALUES (@OffsetGLCo, @ARGLAcct, @ActualCost, @TransDesc, @DetailTransGroup, 'R', @IsReversing)

				INSERT @GLDistributions (GLCo, GLAccount, Amount, [Description], DetailTransGroup, SubType, IsReversing)
				VALUES (@JCGLCo, @APGLAcct, -@ActualCost, @TransDesc, @DetailTransGroup, 'P', @IsReversing)
			END
		END

		SET @DetailTransGroup = @DetailTransGroup + 1
	END

	DECLARE @KeyId int, @GLCo bCompany, @GLAcct bGLAcct, @SubType char(1)
	SET @KeyId = 0

	ValidateGLAccounts:
	BEGIN
		SELECT TOP 1 @KeyId = KeyId, @GLCo = GLCo, @GLAcct = GLAccount, @SubType = SubType
		FROM @GLDistributions
		WHERE KeyId > @KeyId
		ORDER BY KeyId
		IF @@ROWCOUNT = 1
		BEGIN
			EXEC @rcode = dbo.bspGLACfPostable @glco = @GLCo, @glacct = @GLAcct, @chksubtype = @SubType, @msg = @errmsg OUTPUT
			IF @rcode <> 0 RETURN @rcode

			GOTO ValidateGLAccounts
		END
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

	--Capture the current GL Entry
	IF EXISTS(SELECT 1 FROM @GLDistributions WHERE IsReversing = 0)
	BEGIN
		EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @errmsg OUTPUT

		IF @GLEntryID = -1 RETURN 1

		INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
		VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @JCCo)

		UPDATE dbo.vSMWorkCompletedBatch
		SET CurrentRevenueGLEntryID = @GLEntryID
		WHERE SMWorkCompletedID = @SMWorkCompletedID

		--In order for a vSMWorkCompletedGLEntry to be created the amounts for the SM account have to be combined into 1 line
		--Once the posting routine is re-factored to capture what account was hit based on the vSMDetailTransaction then the vSMWorkCompletedGLEntry
		--won't be needed.
		SELECT @ActualCost = SUM(Amount)
		FROM @GLDistributions
		WHERE IsReversing = 0 AND SubType = 'S'

		INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description], DetailTransGroup)
		SELECT  @GLEntryID, 1, GLCo, GLAccount, @ActualCost, @Date, [Description], DetailTransGroup
		FROM @GLDistributions
		WHERE IsReversing = 0 AND SubType = 'S' AND DetailTransGroup = 1
		UNION
		SELECT @GLEntryID, ROW_NUMBER() OVER(ORDER BY KeyId) + 1, GLCo, GLAccount, Amount, @Date, [Description], DetailTransGroup
		FROM @GLDistributions
		WHERE IsReversing = 0 AND SubType <> 'S'

		--The first record inserted should be the gl account derived from SM
		INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
		VALUES (@GLEntryID, 1, @SMWorkCompletedID)
	END
	
	--Capture the reversing GL Entry
	IF EXISTS(SELECT 1 FROM @GLDistributions WHERE IsReversing = 1)
	BEGIN
		EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance =  1, @msg = @errmsg OUTPUT

		IF @GLEntryID = -1 RETURN 1

		INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
		VALUES (@GLEntryID, @BatchCo, @BatchMth, @BatchId, @OldJCCo)

		UPDATE dbo.vSMWorkCompletedBatch
		SET ReversingRevenueGLEntryID = @GLEntryID
		WHERE SMWorkCompletedID = @SMWorkCompletedID

		INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description], DetailTransGroup)
		SELECT @GLEntryID, ROW_NUMBER() OVER(ORDER BY KeyId), GLCo, GLAccount, Amount, @Date, [Description], DetailTransGroup
		FROM @GLDistributions
		WHERE IsReversing = 1
	END

	RETURN 0
END
GO

GRANT EXECUTE ON  [dbo].[vspSMJobCostDistributionInsert] TO [public]
GO
