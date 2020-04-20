SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMInvoiceBatchInsertARBL]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:	Used by SM Invoicing routines to create an ARBL
	*			record.  Not intended to be used by other modules.
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@ARCo bCompany, @BatchMth bMonth, @BatchId int, @BatchSeq int, @BatchTransType char(1), @ARLine int, @LineType char(1), 
   	@LineDescription varchar(30), @ReceivableType int, @GLCo bCompany, @GLAcct bGLAcct, @TaxGroup bGroup, 
   	@TaxCode bTaxCode, @Amount bDollar, @TaxBasis bDollar, @TaxAmount bDollar, @TaxDisc bDollar, 
   	@RetgPct bPct, @Retainage bDollar, @RetgTax bDollar, @DiscOffered bDollar, @DiscTaken bDollar, 
   	@DetailAppliedMth bMonth, @DetailAppliedTrans bTrans, @DetailApplyLine int, @SMWorkCompletedID bigint, 
   	@SMAgreementBillingScheduleID bigint, @ErrMsg varchar(100) output)
	
	as 
	set nocount on
	
	DECLARE @rcode int
   	
	SET @rcode = 0

	INSERT ARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
	RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, TaxDisc, RetgPct, Retainage, RetgTax,
	DiscOffered, DiscTaken, ApplyMth, ApplyTrans, ApplyLine, SMWorkCompletedID, SMAgreementBillingScheduleID)
	VALUES (@ARCo, @BatchMth, @BatchId, @BatchSeq, @ARLine, @BatchTransType, @LineType, @LineDescription, @ReceivableType,
	@GLCo, @GLAcct, @TaxGroup, @TaxCode, isnull(@Amount,0), isnull(@TaxBasis,0), isnull(@TaxAmount,0), 
	isnull(@TaxDisc,0), isnull(@RetgPct,0), isnull(@Retainage,0), isnull(@RetgTax,0), 
	isnull(@DiscOffered,0), isnull(@DiscTaken,0), @DetailAppliedMth, @DetailAppliedTrans, @DetailApplyLine, @SMWorkCompletedID, @SMAgreementBillingScheduleID)
			
	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Unable to create batch header', @rcode = 1
		GOTO vspexit
	END
			 
	vspexit:
	
	RETURN @rcode





GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceBatchInsertARBL] TO [public]
GO
