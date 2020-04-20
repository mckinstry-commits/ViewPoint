SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspAPHBPostSM]
/******************************************************
* CREATED BY:	MarkH  
* MODIFIED By:	MarkH TK07482 Add SMCostType
*				CHS	08/11/2011	- TK-07620
*				MarkH TK-07417
*				JG 01/23/2012  - TK-11971 - Added JCCostType and PhaseGroup
*				TL 03/02/2012 - TK-12858 Added code to update the SMJobCostDistribution table and JC Cost Detail.
*				TL	05/25/2012 TK-15053 added @JCTransType Parameter for vspSMJobCostDistributionInsert /removed @JCTransType for vspSMJobCostDetailInsert
*				EricV 05/29/12 TK-15252 Update Work Completed with all PO Item Line actual costs when InvUnits are zero.
*				Matt B 12/5/12 TK-19963 Update to get price for calculated from rate template on SM work Orders.
*							    TK-19963 Small mod for cost rate
* Usage:
*	
*
* Input params:
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
   
   	(@apco bCompany, @mth bMonth, @batchid int, @dateposted bDate, @errmsg varchar(100) output) 	
AS
BEGIN
	SET NOCOUNT ON
	
	declare @rcode int, @workcompleted int, @batchseq int, @apline int, @smco bCompany, @smworkorder int, @smtype tinyint,
	@DefaultSMGLCo bCompany, @DefaultCostAcct bGLAcct, @DefaultRevenueAcct bGLAcct,
  	@DefaultCostWIPAcct bGLAcct, @DefaultRevenueWIPAcct bGLAcct, @smscope int, @aptrans bTrans,
  	@apkeyid bigint, @po varchar(30), @poitem bItem, @POItemLine int,
  	
	@smservicesite varchar(20), @apinvdate bDate, @um bUM, @units bUnits, @unitcost bUnitCost, @grossamt bDollar,
	@totalamt bDollar, @taxgroup bGroup, @actualamt bDollar, @smdesc varchar(60), @glco bCompany, @glacct bGLAcct,
	@oldnew tinyint, @transtype char(1), @SMWorkCompletedID bigint, @acf bUnitCost, @smtaxcode bTaxCode, @taxamt bDollar,
	@taxtype tinyint, @poit_um bUM, @smcosttype smallint, @smglentryid int, @smgldetailtransid INT, @rowcount int, @GLDetailTransactionEntryIDToDelete bigint, @GLEntryIDToDelete bigint,
	@jccosttype dbo.bJCCType, @phasegroup dbo.bGroup,  @UseJCInterface bYN, @CostDetailID bigint, @HQBatchLineID bigint, @bcAPSM cursor,
 
	--Get Material and price information
	@MaterialGroup bGroup, @Material bMatl, @MaterialUM bUM, @Quantity bUnits,
	@CostRate bUnitCost,
	@PriceRate bUnitCost, @PriceTotal bDollar,						
	--Get Agreement Information
	@Agreement Varchar(15), @Revision int, @Coverage char(1)
 
	DECLARE @SMGLTransactions TABLE (GLCo bCompany, GLAcct bGLAcct, TotalCost bDollar, InvDate bDate, IsTransactionForSMDerivedAccount bit)
	
	DECLARE @POItemLines TABLE (PO varchar(30), POItem int, POItemLine int)
	INSERT @POItemLines
	SELECT DISTINCT PO, POItem, POItemLine
	FROM vAPSM WHERE APCo = @apco and Mth = @mth and BatchId = @batchid AND SMType = 5
	
	select @rcode = 0

	/*Clear records from SMJostCostDistribution for each APTL seq or key id*/
	DELETE dbo.vSMJobCostDistribution
	WHERE BatchCo = @apco AND BatchMth = @mth AND BatchID = @batchid
	
	/*Clear records currently being created by job related work orders*/
	EXEC @rcode = dbo.vspSMWorkCompletedBatchClear @BatchCo = @apco, @BatchMonth = @mth, @BatchId = @batchid, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SET @bcAPSM = CURSOR LOCAL FAST_FORWARD FOR
	SELECT vAPSM.BatchSeq, vAPSM.APLine, vAPSM.SMCo, vAPSM.SMServiceSite, vAPSM.SMWorkOrder, vAPSM.Scope, vAPSM.SMType,
	vAPSM.APInvDate, vAPSM.UM, vAPSM.Units, vAPSM.UnitCost, vAPSM.GrossAmt, vAPSM.TotalAmt, vAPSM.TaxGroup, vAPSM.ActualAmt, vAPSM.SMDescription, vAPSM.GLCo,
	vAPSM.GLAcct, vAPSM.APTrans, APKeyID, vAPSM.OldNew, vAPSM.TransType, vAPSM.SMWorkCompletedID, 
	vAPSM.PO, vAPSM.POItem, vAPSM.POItemLine, vAPSM.TaxCode, vAPSM.TaxAmt, vAPSM.TaxType, vAPSM.SMCostType, vAPSM.JCCostType, vAPSM.PhaseGroup,
	bAPTL.MatlGroup, bAPTL.Material, bAPTL.UM, bAPTL.Units, 
	CASE WHEN bAPTL.Units=0 THEN NULL ELSE 
		(vAPSM.TotalAmt/bAPTL.Units)
	END, -- Cost Rate for SM
	Agreement, Revision,
	CASE WHEN SMWorkOrderScope.Agreement IS NULL THEN NULL
		WHEN SMWorkOrderScope.PriceMethod='T' AND SMWorkOrderScope.UseAgreementRates='Y' THEN 'A'
		WHEN SMWorkOrderScope.PriceMethod='C' THEN 'C'
		ELSE NULL END Coverage
	FROM vAPSM
	LEFT JOIN bAPTL ON 
	vAPSM.APKeyID = bAPTL.KeyID
	LEFT JOIN SMWorkOrderScope ON
	bAPTL.SMCo = SMWorkOrderScope.SMCo  AND
	bAPTL.SMWorkOrder = SMWorkOrderScope.WorkOrder AND
	bAPTL.Scope = SMWorkOrderScope.Scope
	WHERE vAPSM.APCo = @apco and vAPSM.Mth = @mth and vAPSM.BatchId = @batchid
	ORDER BY CASE TransType WHEN 'D' THEN 1 WHEN 'C' THEN 2 ELSE 3 END
	--Process the deletes first so that 2 work completed don't end up pointing to the same detail id
	
	OPEN @bcAPSM
	FETCH NEXT from @bcAPSM into @batchseq, @apline, @smco, @smservicesite, @smworkorder, @smscope, @smtype,
	@apinvdate, @um, @units, @unitcost, @grossamt, @totalamt, @taxgroup, @actualamt, @smdesc, @glco, 
	@glacct, @aptrans, @apkeyid, @oldnew, @transtype, @SMWorkCompletedID, 
	@po, @poitem, @POItemLine, @smtaxcode, @taxamt, @taxtype, @smcosttype, @jccosttype, @phasegroup,
	@MaterialGroup, @Material, @MaterialUM, @Quantity, @CostRate,
	@Agreement, @Revision, @Coverage
	
	BEGIN TRY
		BEGIN TRAN
		
		WHILE @@fetch_status = 0
		BEGIN
			IF @smtype = 3  --Misc line type in SM
			BEGIN
				IF @transtype <> 'D'
				BEGIN
					DELETE vAPSM WHERE APKeyID = @apkeyid and OldNew = @oldnew and
						--these parameters prevent sm work completed id  update error when SM WorkOrder/Scope/J
			   			APCo=@apco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq and APLine=@apline
					IF @@rowcount <> 1
					BEGIN
						SELECT @errmsg = 'Unable to delete item from vAPSM - Misc'
						ROLLBACK TRAN
						EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
						RETURN 1
					END
				END

				SELECT @CostDetailID = HQDetailID, @HQBatchLineID = HQBatchLineID 
				FROM dbo.vHQBatchLine
				WHERE Co = @apco AND Mth = @mth AND BatchId = @batchid AND Seq = @batchseq AND Line = @apline

				--IMPORTANT NOTE: For AP transaction that have had the SMCo, WorkOrder, or Scope change
				--during validation an Add APSM and Delete APSM record are created. This also applys to
				--when the AP transaction line type is changed from or to the SM line type creating either
				--an add or delete record.
				--For a normal change 2 Change APSM records are created with one being marked as old and the other as new
				IF @oldnew = 1
				BEGIN
					IF @transtype = 'A'
					BEGIN
						--Develop the Work Completed seq for the work order
						SELECT @workcompleted = dbo.vfSMGetNextWorkCompletedSeq(@smco, @smworkorder)
						SELECT @PriceRate=Null, @PriceTotal=Null
						--change to check that it exists in hqmt both material group and material as key												
						if EXISTS (SELECT TOP 1 Material FROM bHQMT WHERE MatlGroup = @MaterialGroup AND Material = @Material)
						BEGIN
							SELECT @PriceRate = PriceRate, @PriceTotal = PriceTotal
							FROM dbo.vfSMRatePurchase(@smco, @smworkorder, @smscope, @apinvdate, @Agreement, @Revision, @Coverage, @MaterialGroup, @Material, @MaterialUM, @Quantity, @actualamt, @MaterialUM, 'E')
						END
						
						IF @PriceTotal IS NULL
						BEGIN
							SELECT @PriceTotal = @actualamt, @PriceRate= @CostRate
						END
						
						--Get work completed default gl accounts
						SELECT
							@DefaultSMGLCo = GLCo,
							@DefaultCostAcct = CostGLAcct,
							@DefaultRevenueAcct = RevenueGLAcct,
							@DefaultCostWIPAcct = CostWIPGLAcct,
							@DefaultRevenueWIPAcct = RevenueWIPGLAcct
						FROM vfSMGetAccountingTreatment(@smco, @smworkorder, @smscope, @smtype, @smcosttype)

						INSERT SMWorkCompleted ([Type], SMCo, WorkOrder, WorkCompleted, Scope, [Date],
						ServiceSite, TaxGroup, GLCo, CostAccount, RevenueAccount, CostWIPAccount, RevenueWIPAccount,
						ActualCost, CostQuantity, CostRate, PriceQuantity, PriceRate, PriceTotal, [Description], 
						NoCharge, APTLKeyID, TaxCode, TaxType, TaxBasis, TaxAmount, MonthToPostCost, SMCostType,
						JCCostType, PhaseGroup, CostDetailID, Agreement, Revision, Coverage)

						VALUES(@smtype, @smco, @smworkorder, @workcompleted, @smscope, @apinvdate,
						@smservicesite, @taxgroup, @DefaultSMGLCo, @DefaultCostAcct, @DefaultRevenueAcct, @DefaultCostWIPAcct, @DefaultRevenueWIPAcct, 
						@totalamt, CASE @units WHEN 0 THEN null ELSE @units END, 
						CASE @CostRate WHEN 0 THEN null ELSE @CostRate END, 
						CASE @units WHEN 0 THEN null ELSE @units END,
						@PriceRate, @PriceTotal, @smdesc, 'N', @apkeyid, @smtaxcode, @taxtype, 
						CASE 
							WHEN @smtaxcode IS NULL THEN NULL
							ELSE @PriceTotal
						END
						, 
						@taxamt, @mth, @smcosttype, @jccosttype, @phasegroup, @CostDetailID, @Agreement, @Revision, @Coverage)

						SELECT @SMWorkCompletedID = SMWorkCompletedID 
						FROM SMWorkCompleted WHERE [Type] = @smtype and SMCo = @smco and WorkOrder = 
						@smworkorder and WorkCompleted = @workcompleted
						
						--The detail transactions don't have the SMWorkCompletedID set yet.
						UPDATE vSMDetailTransaction
						SET SMWorkCompletedID = @SMWorkCompletedID
						FROM dbo.vSMDetailTransaction
							INNER JOIN dbo.vSMWorkOrderScope ON vSMDetailTransaction.SMWorkOrderScopeID = vSMWorkOrderScope.SMWorkOrderScopeID
						--There may be a reversing and correcting entry tied to 1 HQBatchLine. In order to prevent updating the reversing entry's SMWorkCompletedID (which is now null because of cascade null) the scope
						--values are used to make sure and only update the correcting entry.
						WHERE vSMDetailTransaction.HQBatchLineID = @HQBatchLineID AND vSMWorkOrderScope.SMCo = @smco AND vSMWorkOrderScope.WorkOrder = @smworkorder AND vSMWorkOrderScope.Scope = @smscope
						
						--Create a SMWorkCompletedGL so that WIP transfer works
						INSERT vSMWorkCompletedGL(SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
						VALUES (@SMWorkCompletedID, @smco, 0)
					END
					ELSE IF @transtype = 'C'
					BEGIN	
						SELECT @PriceRate=Null, @PriceTotal=Null							
						--change to check that it exists in hqmt both material group and material as key												
						if EXISTS (SELECT TOP 1 Material FROM bHQMT WHERE MatlGroup = @MaterialGroup AND Material = @Material)
						BEGIN
							SELECT @PriceRate = PriceRate, @PriceTotal = PriceTotal
							FROM dbo.vfSMRatePurchase(@smco, @smworkorder, @smscope, @apinvdate, @Agreement, @Revision, @Coverage, @MaterialGroup, @Material, @MaterialUM, @Quantity, @actualamt, @MaterialUM, 'E')
						END
						
						IF @PriceTotal IS NULL
						BEGIN
							SELECT @PriceTotal = @actualamt, @PriceRate= @CostRate
						END

						--If SMInvoiceId is not null can only update cost fields not price fields
						IF Exists(SELECT 1 FROM SMWorkCompleted WHERE APTLKeyID = @apkeyid AND SMInvoiceID IS NULL)
						BEGIN
						UPDATE dbo.SMWorkCompleted
						SET
							CostQuantity = CASE @units WHEN 0 THEN null ELSE @units END,
							CostRate = CASE @CostRate WHEN 0 THEN null ELSE @CostRate END,
							ActualCost = @actualamt, 
							PriceQuantity = CASE @units WHEN 0 THEN null ELSE @units END,
							PriceRate = CASE @PriceRate WHEN 0 THEN null ELSE @PriceRate END,
							PriceTotal = @PriceTotal, 
							[Description] = @smdesc, 
							TaxType = @taxtype,
							TaxCode = @smtaxcode,
							TaxBasis =
							CASE 
								WHEN @smtaxcode IS NULL THEN NULL
									ELSE @PriceTotal
							END,
							TaxAmount = @taxamt,
							SMCostType = @smcosttype,
							JCCostType = @jccosttype,
							PhaseGroup = @phasegroup
						WHERE APTLKeyID = @apkeyid
					END
						ELSE
						BEGIN
							UPDATE dbo.SMWorkCompleted
							SET
							CostQuantity = CASE @units WHEN 0 THEN null ELSE @units END,
							CostRate = CASE @CostRate WHEN 0 THEN null ELSE @CostRate END,
							ActualCost = @actualamt, 													
							[Description] = @smdesc, 
							SMCostType = @smcosttype,
							JCCostType = @jccosttype,
							PhaseGroup = @phasegroup
							WHERE APTLKeyID = @apkeyid
						END
					END

					/*BEGIN CAPTURE OF ADDED OR UPDATED WORK COMPLETED GL COST FOR SM WIP*/
					INSERT vSMGLEntry(SMWorkCompletedID, TransactionsShouldBalance)
					VALUES(@SMWorkCompletedID, 0)

					SELECT @smglentryid = SCOPE_IDENTITY()

					INSERT vSMGLDetailTransaction(SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
					SELECT @smglentryid, 1 AS IsTransactionForSMDerivedAccount, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, vGLEntryTransaction.Amount, vGLEntryTransaction.ActDate, 'Post from AP'
					FROM dbo.vGLEntryBatch
						INNER JOIN dbo.vAPTLGLEntry ON vGLEntryBatch.GLEntryID = vAPTLGLEntry.GLEntryID
						INNER JOIN dbo.vGLEntryTransaction ON vAPTLGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND vAPTLGLEntry.GLTransactionForAPTransactionLineAccount = vGLEntryTransaction.GLTransaction
					WHERE vGLEntryBatch.Co = @apco AND vGLEntryBatch.Mth= @mth AND vGLEntryBatch.BatchId = @batchid AND vGLEntryBatch.BatchSeq = @batchseq AND vGLEntryBatch.Line = @apline

					SELECT @smgldetailtransid = SCOPE_IDENTITY(), @rowcount = @@rowcount

					IF @rowcount <> 1
					BEGIN
						SELECT @errmsg = 'Unable to find the sm derived account'
						ROLLBACK TRAN
						EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
						RETURN 1
					END
				
					UPDATE vSMWorkCompletedGL
					SET 
						CostGLDetailTransactionID = @smgldetailtransid,
						@GLDetailTransactionEntryIDToDelete = CostGLDetailTransactionEntryID,
						CostGLDetailTransactionEntryID = @smglentryid,
						@GLEntryIDToDelete = CostGLEntryID,
						CostGLEntryID = @smglentryid
					WHERE SMWorkCompletedID = @SMWorkCompletedID
					
					DELETE dbo.vSMGLEntry WHERE SMGLEntryID IN (@GLDetailTransactionEntryIDToDelete, @GLEntryIDToDelete)
					/*END CAPTURE OF ADDED OR UPDATED WORK COMPLETED GL COST FOR SM WIP*/
					
					/*BEGIN CAPTURE OF ADDED OR UPDATE WORK COMPLETED JC COSTS AND GL*/
					IF EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID AND vSMWorkOrder.Job IS NOT NULL)
					BEGIN
						INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
						SELECT 0 IsReversing, 1 Posted, SMWorkCompleted.CostDetailID, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, SMWorkCompleted.[Type], 'R' TransactionType, @apco, @mth, @batchid, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount, -ISNULL(SMWorkCompleted.PriceTotal, 0)
						FROM dbo.SMWorkCompleted--Use the SMWorkCompleted view to filter out the deleted records
							INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
							INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
							CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompleted.SMWorkCompletedID)
						WHERE SMWorkCompleted.CostDetailID = @CostDetailID
						
						IF EXISTS(SELECT 1 FROM dbo.SMCO WHERE SMCo = @smco AND UseJCInterface = 'Y')
						BEGIN
							EXEC @rcode = dbo.vspSMJobCostDistributionInsert @SMWorkCompletedID=@SMWorkCompletedID, @BatchCo=@apco,@BatchMth=@mth,@BatchId = @batchid, @JCTransType='AP',@errmsg = @errmsg OUTPUT
							IF @rcode <> 0 
							BEGIN
								SELECT @errmsg = @errmsg + ' - Unable to create SM Job Cost Distribution record.'
								ROLLBACK TRAN
								EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
								RETURN @rcode
							END
						END
					END
					/*END CAPTURE OF ADDED OR UPDATE WORK COMPLETED JC COSTS AND GL*/
					
					--Update costs captured
					UPDATE dbo.vSMWorkCompleted 
					SET InitialCostsCaptured = 1, CostsCaptured = 1
					WHERE SMWorkCompletedID = @SMWorkCompletedID 
				END
				ELSE
				BEGIN
					IF EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID AND vSMWorkOrder.Job IS NOT NULL) 
					BEGIN
						INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
						SELECT 1 IsReversing, 1 Posted, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, @apco, @mth, @batchid, GLCo, GLAccount, -SUM(Amount)
						FROM dbo.vSMDetailTransaction
						WHERE HQDetailID = @CostDetailID AND Posted = 1 AND TransactionType = 'R'
						GROUP BY HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, GLCo, GLAccount
						HAVING SUM(Amount) <> 0
					END

					IF @transtype = 'D'
					BEGIN
						/*BEGIN CAPTURE OF ADDED OR UPDATE WORK COMPLETED JC COSTS AND GL*/
						IF EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID AND vSMWorkOrder.Job IS NOT NULL) 
							AND EXISTS(SELECT 1 FROM dbo.SMCO WHERE SMCo = @smco AND UseJCInterface = 'Y')
						BEGIN
							UPDATE dbo.vSMWorkCompleted
							SET IsDeleted = 1
							WHERE SMWorkCompletedID = @SMWorkCompletedID
							
							EXEC @rcode = dbo.vspSMJobCostDistributionInsert @SMWorkCompletedID=@SMWorkCompletedID, @BatchCo=@apco,@BatchMth=@mth,@BatchId = @batchid, @JCTransType='AP',@errmsg = @errmsg OUTPUT
							IF @rcode <> 0 
							BEGIN
								SELECT @errmsg = @errmsg + ' - Unable to create SM Job Cost Distribution record.'
								ROLLBACK TRAN
								EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
								RETURN @rcode
							END
							
							--Since the work completed wasn't actually deleted it shouldn't be marked as such so that it still displays.
							UPDATE dbo.vSMWorkCompleted
							SET IsDeleted = 0
							WHERE SMWorkCompletedID = @SMWorkCompletedID
						END
						/*END CAPTURE OF ADDED OR UPDATE WORK COMPLETED JC COSTS AND GL*/
						
						--Clear the costs for the work completed
						UPDATE vSMWorkCompletedGL
						SET 
							CostGLDetailTransactionID = NULL,
							@GLDetailTransactionEntryIDToDelete = CostGLDetailTransactionEntryID,
							CostGLDetailTransactionEntryID = NULL,
							@GLEntryIDToDelete = CostGLEntryID,
							CostGLEntryID = NULL
						WHERE SMWorkCompletedID = @SMWorkCompletedID
						
						DELETE dbo.vSMGLEntry WHERE SMGLEntryID IN (@GLDetailTransactionEntryIDToDelete, @GLEntryIDToDelete)
					
						--If Work Completed record has been billed, do not delete the record.  Just zero out the
						--CostQuantity, CostRate, and ActualCost.
						IF EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID AND SMInvoiceID IS NOT NULL)
						BEGIN
							--Assign the work completed a new detail so that if a new work completed is created
							--both work completed aren't pointing to the same detail id. Also if the work completed
							--is pointing to the same detail then it would get deleted later on in the posting which is undesired in this case.
							EXEC @rcode = dbo.vspHQDetailCreate @Source = 'AP Entry', @HQDetailID = @CostDetailID OUTPUT, @msg = @errmsg OUTPUT
							IF @rcode <> 0 
							BEGIN
								SELECT @errmsg = @errmsg + ' - Unable to update work completed with new detail.'
								ROLLBACK TRAN
								EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
								RETURN @rcode
							END

							UPDATE dbo.SMWorkCompleted 
							SET APTLKeyID = NULL, CostDetailID = @CostDetailID, InitialCostsCaptured = 1, CostsCaptured = 1, CostQuantity = NULL, CostRate = NULL, ActualCost = NULL
							WHERE SMWorkCompletedID = @SMWorkCompletedID
						END
						ELSE
						BEGIN
							--Wait to delete the work completed after the reversing job entries are posted.
						
							UPDATE vSMWorkCompletedGL
							SET 
								RevenueGLDetailTransactionID = NULL,
								@GLDetailTransactionEntryIDToDelete = RevenueGLDetailTransactionEntryID,
								RevenueGLDetailTransactionEntryID = NULL,
								@GLEntryIDToDelete = RevenueGLEntryID,
								RevenueGLEntryID = NULL
							WHERE SMWorkCompletedID = @SMWorkCompletedID
							
							DELETE dbo.vSMGLEntry WHERE SMGLEntryID IN (@GLDetailTransactionEntryIDToDelete, @GLEntryIDToDelete)

							DELETE dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID
						END
					END
				END
			END

			FETCH NEXT from @bcAPSM into @batchseq, @apline, @smco, @smservicesite, @smworkorder, @smscope, @smtype,
			@apinvdate, @um, @units, @unitcost, @grossamt, @totalamt, @taxgroup, @actualamt, @smdesc, @glco, 
			@glacct, @aptrans, @apkeyid, @oldnew, @transtype, @SMWorkCompletedID, 
			@po, @poitem, @POItemLine, @smtaxcode, @taxamt, @taxtype, @smcosttype, @jccosttype, @phasegroup,
			@MaterialGroup, @Material, @MaterialUM, @Quantity, @CostRate,
			@Agreement, @Revision, @Coverage
		END

		--After all records in the batch have been processed,, create JOB COST DETAIL RECORD/UPDATE
		EXEC @rcode = dbo.vspSMJobCostDetailInsert  @BatchCo=@apco,@BatchMth=@mth,@BatchId = @batchid, @errmsg=@errmsg OUTPUT
		IF @rcode <> 0
		BEGIN
			SELECT @errmsg = @errmsg + ' - Unable to update Job Cost Detail.'
			ROLLBACK TRAN
			EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
			RETURN @rcode
		END
		
		--Use the table to delete because we have already captured the reversing cost
		--and using the view will only mark the work completed as deleted. We actually want to delete it.
		DELETE vSMWorkCompleted
		FROM dbo.vAPSM
			INNER JOIN dbo.vSMWorkCompleted ON vAPSM.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		WHERE vAPSM.APCo = @apco AND vAPSM.Mth = @mth AND vAPSM.BatchId = @batchid AND vAPSM.SMType = 3 AND vAPSM.TransType = 'D' AND 
			NOT EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE vAPSM.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID AND SMWorkCompleted.SMInvoiceID IS NOT NULL)
		
		DELETE dbo.vAPSM
		WHERE APCo = @apco AND Mth = @mth AND BatchId = @batchid AND SMType = 3 AND TransType = 'D'
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		--If the error is due to a transaction count mismatch in vspSMJobCostDetailInsert
		--then it is more helpful to keep the error message from vspSMJobCostDetailInsert.
		IF ERROR_NUMBER() <> 266 SET @errmsg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		
		EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
		
		RETURN 1
	END CATCH

	EXEC dbo.vspCleanupCursor @Cursor = @bcAPSM
	
	BEGIN TRY
		BEGIN TRAN
	
		--Update the SMPOItemLine values before distributing costs amongst work completed
		;WITH POItemLineUpdateCTE
		AS
		(
			SELECT vPOItemLineDistribution.POCo, vPOItemLineDistribution.PO, vPOItemLineDistribution.POItem, vPOItemLineDistribution.POItemLine,
				SUM(vPOItemLineDistribution.InvTaxBasis) InvTaxBasis, SUM(vPOItemLineDistribution.InvDirectExpenseTax) InvDirectExpenseTax, SUM(vPOItemLineDistribution.InvTotalCost) InvTotalCost
			FROM dbo.vHQBatchDistribution
				INNER JOIN dbo.vPOItemLineDistribution ON vHQBatchDistribution.HQBatchDistributionID = vPOItemLineDistribution.HQBatchDistributionID
			WHERE vHQBatchDistribution.Co = @apco AND vHQBatchDistribution.Mth = @mth AND vHQBatchDistribution.BatchId = @batchid
			GROUP BY vPOItemLineDistribution.POCo, vPOItemLineDistribution.PO, vPOItemLineDistribution.POItem, vPOItemLineDistribution.POItemLine
		)
		UPDATE vSMPOItemLine
		SET
			InvTaxBasis = vSMPOItemLine.InvTaxBasis + ISNULL(POItemLineUpdateCTE.InvTaxBasis, 0),
			InvDirectExpenseTax = vSMPOItemLine.InvDirectExpenseTax + ISNULL(POItemLineUpdateCTE.InvDirectExpenseTax, 0),
			InvTotalCost = vSMPOItemLine.InvTotalCost + ISNULL(POItemLineUpdateCTE.InvTotalCost, 0)
		FROM POItemLineUpdateCTE
			INNER JOIN dbo.vSMPOItemLine ON POItemLineUpdateCTE.POCo = vSMPOItemLine.POCo AND POItemLineUpdateCTE.PO = vSMPOItemLine.PO AND POItemLineUpdateCTE.POItem = vSMPOItemLine.POItem AND POItemLineUpdateCTE.POItemLine = vSMPOItemLine.POItemLine

		DELETE dbo.vPOItemLineDistribution
		FROM dbo.vHQBatchDistribution
			INNER JOIN dbo.vPOItemLineDistribution ON vHQBatchDistribution.HQBatchDistributionID = vPOItemLineDistribution.HQBatchDistributionID
		WHERE vHQBatchDistribution.Co = @apco AND vHQBatchDistribution.Mth = @mth AND vHQBatchDistribution.BatchId = @batchid
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		RETURN 1
	END CATCH

	BEGIN TRY	
		BEGIN TRAN
		
		WHILE EXISTS(SELECT 1 FROM @POItemLines)
		BEGIN
			SELECT TOP 1 @po = PO, @poitem = POItem, @POItemLine = POItemLine
			FROM @POItemLines
			
			EXEC @rcode = dbo.vspSMWorkCompletedAPUpdate @apco, @mth, @batchid, @po, @poitem, @POItemLine, @errmsg OUTPUT
			IF @rcode <> 0
			BEGIN			
				ROLLBACK TRAN
				RETURN @rcode
			END
			
			DELETE @POItemLines
			WHERE PO = @po AND POItem = @poitem AND POItemLine = @POItemLine
		END

		/*START JOB COST DETAIL RECORD UPDATE*/	
		EXEC @rcode = dbo.vspSMJobCostDetailInsert @BatchCo = @apco, @BatchMth = @mth, @BatchId = @batchid, @errmsg = @errmsg OUTPUT
		IF @rcode <> 0
		BEGIN
			ROLLBACK TRAN
			RETURN @rcode
		END
		/*END JOB COST DETAIL RECORD UPDATE*/
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		--If the error is due to a transaction count mismatch in vspSMWorkCompletedAPUpdate
		--then it is more helpful to keep the error message from vspSMWorkCompletedAPUpdate.
		IF ERROR_NUMBER() <> 266 SET @errmsg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		
		RETURN 1
	END CATCH

	DELETE FROM vAPSM WHERE APCo = @apco AND Mth = @mth AND BatchId = @batchid AND SMType = 5
	
	EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @apco, @BatchMth = @mth, @BatchId = @batchid, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspAPHBPostSM] TO [public]
GO
