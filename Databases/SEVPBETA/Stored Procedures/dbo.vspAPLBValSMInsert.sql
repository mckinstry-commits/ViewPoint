SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspAPLBValSMInsert]
/******************************************************
* CREATED BY: Mark H
* MODIFIED By:  TRL	07/27/2011	- TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				MH	08/09/2011	- TK-07482	Removed MiscellaneousType and added SMCostType
*				CHS	08/10/2011	- TK-07620 - added POItemLine
*				JG	01/23/2012  - TK-11971 - Added JCCostType and PhaseGroup
*				TL		3/02/2012  - TK- 12858 add @smworkcompletedid variable and parameter for C or D transaction for SM Work Completed Items
*				TL     03/19/2012 - TK - 13408 fixed code for SM/JC TaxCode Phase/Cost Redirect
*				TL    04/16/2012 - TK-13994 Added code to update Phase in APSM
*				EricV 05/10/2012 - TK-14622 Check POItemLine when inserting.
* Usage:  Queues up distribution to SM
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
   
   	(@apco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, 
   	@linetype tinyint, @aptrans bTrans, @apkeyid bigint, 
   	@apline int, @smco bCompany, @smservicesite varchar(20), 
   	@smworkorder int, @smscope int, @smtype tinyint, 
   	@smcosttype smallint, @jccosttype dbo.bJCCType, @phasegroup dbo.bGroup,@phase bPhase,
   	@po varchar(30), @poitem bItem, @POItemLine int, 
   	@apinvoicedate bDate, @um bUM, @units bUnits, @unitcost bUnitCost, 
   	@grossamt bDollar, @totalcost bDollar, @taxgroup bGroup,  
   	@description varchar(60), @glco bCompany, @glacct bGLAcct, 
   	@oldnew tinyint, @miscyn bYN, @miscamt bDollar, 
   	@transtype char(1), @smtaxcode bTaxCode, @taxamt bDollar, @taxtype tinyint)
	
   	
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode tinyint,@smworkcompletedid bigint

	select  @smworkcompletedid  = SMWorkCompletedID from dbo.vSMWorkCompleted Where APTLKeyID=@apkeyid
     
	IF @linetype = 8 -- SM Miscellaneous Type
	BEGIN
			
		INSERT vAPSM(APCo, Mth, BatchId, BatchSeq, APTrans, APKeyID, 
			APLine, SMCo, SMWorkOrder, SMType, SMServiceSite, Scope, SMWorkCompletedID,
			SMCostType, JCCostType, PhaseGroup, Phase, APInvDate, UM, Units, UnitCost, GrossAmt, TotalAmt, 
			ActualAmt, SMDescription, GLCo, GLAcct, TaxGroup, OldNew, TransType, TaxAmt, TaxType, TaxCode, PriceTotal)
			
		VALUES (@apco, @mth, @batchid, @batchseq, @aptrans, @apkeyid, 
			@apline, @smco, @smworkorder, @smtype, @smservicesite, @smscope,  @smworkcompletedid,
			@smcosttype, @jccosttype, @phasegroup, @phase, @apinvoicedate, @um, @units, @unitcost, @grossamt, @totalcost,  
			@totalcost, @description, @glco, @glacct, @taxgroup, @oldnew, @transtype, @taxamt, @taxtype, @smtaxcode, @totalcost)

		IF @@rowcount = 1
		BEGIN
			RETURN 0
		END
		ELSE
		BEGIN
			RETURN 1
		END		 
	END

	IF @linetype = 6  -- SM PO Type
	BEGIN
		IF @oldnew = 0
		BEGIN
			
			IF @transtype = 'C'
			BEGIN
				DECLARE @olddistribfactor bUnitCost
		
				----Load up vAPSM with Work Completed Records for this PO
				INSERT vAPSM(APCo, Mth, BatchId, BatchSeq, APTrans, APLine, 
					SMCo, SMWorkOrder, Scope, SMType, WorkCompleted, SMWorkCompletedID, 
					OldNew, TransType, PO, POItem,POItemLine,JCCostType,PhaseGroup,Phase)
				
				SELECT @apco, @mth, @batchid, @batchseq, @aptrans, @apline, 
					SMCo, WorkOrder, Scope, [Type], WorkCompleted, SMWorkCompletedID, 
					@oldnew, @transtype, @po, @poitem,@POItemLine,@jccosttype,@phasegroup,@phase
				FROM SMWorkCompleted 
				WHERE SMCo = @smco 
					AND WorkOrder = @smworkorder 
					AND POCo = @apco 
					AND PONumber = @po 
					AND POItem = @poitem 				
					AND POItemLine = @POItemLine
				
			END
			ELSE IF @transtype = 'D'
			BEGIN
				
				IF NOT EXISTS (SELECT 1 
								FROM vAPSM 
								WHERE APCo = @apco 
									AND Mth = @mth 
									AND BatchId = @batchid
									AND BatchSeq = @batchseq
									AND PO = @po
									AND POItem = @poitem
									AND POItemLine = @POItemLine)
				BEGIN
					INSERT vAPSM(APCo, Mth, BatchId, BatchSeq, APTrans, APLine, 
						SMCo, SMWorkOrder, Scope, SMType, WorkCompleted, SMWorkCompletedID, 
						Units, UnitCost, TotalAmt, OldNew, TransType, PO, POItem,POItemLine,JCCostType,PhaseGroup,Phase)

					SELECT @apco, @mth, @batchid, @batchseq, @aptrans, @apline, 
						SMCo, WorkOrder, Scope, [Type], WorkCompleted, SMWorkCompletedID, 
						Quantity, CostRate,0, @oldnew, @transtype, @po, @poitem,@POItemLine,@jccosttype,@phasegroup,@phase
					FROM SMWorkCompleted 
					WHERE SMCo = @smco 
						AND WorkOrder = @smworkorder 
						AND POCo = @apco 
						AND PONumber = @po 
						AND POItem = @poitem 
						AND POItemLine = @POItemLine

				END
			END
		END
		ELSE IF @oldnew = 1
		BEGIN 
			IF @transtype = 'A' or @transtype = 'C'
			BEGIN
				----Load up vAPSM with Work Completed Records for this PO
				INSERT vAPSM(APCo, Mth, BatchId, BatchSeq, APTrans, APLine, 
					SMCo, SMWorkOrder, Scope, SMType, WorkCompleted, SMWorkCompletedID, 
					OldNew, TransType, PO, POItem, POItemLine, JCCostType,PhaseGroup,Phase)
				
				SELECT @apco, @mth, @batchid, @batchseq, @aptrans, @apline, 
					SMCo, WorkOrder, Scope, [Type], WorkCompleted, SMWorkCompletedID, 
					@oldnew, @transtype, @po, @poitem, @POItemLine, @jccosttype,@phasegroup,@phase
					
				FROM SMWorkCompleted 
				WHERE SMCo = @smco 
					AND WorkOrder = @smworkorder 
					AND POCo = @apco 
					AND PONumber = @po 
					AND POItem = @poitem 
					AND POItemLine = @POItemLine
			END
		END
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspAPLBValSMInsert] TO [public]
GO
