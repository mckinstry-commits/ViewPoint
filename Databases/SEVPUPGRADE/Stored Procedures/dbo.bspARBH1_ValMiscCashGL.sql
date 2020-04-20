SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValMiscCashGL    Script Date: 8/28/99 9:36:04 AM ******/
CREATE procedure [dbo].[bspARBH1_ValMiscCashGL]
/***********************************************************
* CREATED BY:   JRE 8/17/97
* MODIFIED By :  bc 8/21/98
* 		bc 09/21/00 when @i = 3 write the description out to ARBA as 'Cash Account'
* 		bc 10/26/00 - recoded x-company gl distributions
*		TJL 08/07/01 - Corrected Cross Company Auditing 2nd time.
*				 	Added @Equipment for use when updating bARBA
*		TJL 04/23/02 - Issue #17082, Catch improper GLAcct SubTypes during GLAcct validation.
*		TJL 08/07/02 - Issue #17995, Rewrite GL processing (incl InterCompany). More inline w/CashRec
*		TJL 02/27/03 - Issue #20074, Use Detail Description from MiscRec Detail for Cash GLAcct related entries
*		TJL 07/20/09 - Issue #134874, When Job is Final Closed, Expense changes need to be posted to Closed WIP Accounts
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*
* USAGE:
* Validates each entry in bARBL for a selected batch - called from bARBHCashVal
* ***** @InterCompany is very important, make sure you set it correctly *****
* Errors in batch added to bHQBE using bspHQBEInsert
*
* GL Account distributions added to bARBA
*
* GL debit and credit totals must balance.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   BatchSeq    Batch Seq to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/

@ARCo bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @errmsg varchar(255) output
as

set nocount on
   
declare @errortext varchar(255),  @errorstart varchar(50), @rcode int,@errdetail varchar(60), @i tinyint,
   	@PostAmount bDollar, @oldPostAmount bDollar, @SortName varchar(15), @ActDate bDate,
   	@PaymentJrnl bJrnl, @GLPayLevel int, @MiscCashJrnl bJrnl, @GLMiscCashLevel int,
   	@InterCompany tinyint, @old varchar(30), @new varchar(30),@OldNew tinyint,
   	@DistDate bDate, @oldDistDate bDate, @TaxInterface bYN, @TaxPhase bPhase,@TaxCostType bJCCType,
   	@SeperateTax bYN,@PostTax bDollar, @chksubtype char(1), @compareICamt bDollar, @compareIColdamt bDollar
   
/*Declare AR Header variables*/
declare @TransType char(1), @ARTrans bTrans,@CheckNo char(10), @ARTransType char(1),  @Source bSource,
   	@TransDate bDate, @CMCo bCompany, @CMAcct bCMAcct, @CreditAmt bDollar,@oldTransDate bDate,
   	@oldCMCo bCompany, @oldCMAcct bCMAcct, @oldCheckNo char(10), @oldCreditAmt bDollar
   
/*Declare AR Line variables */
declare @ARLine smallint, @TransTypeLine char(1),@RecType tinyint, @LineType char, @GLCo bCompany, @GLAcct bGLAcct,
   	@Description bDesc, @TaxGroup bGroup, @TaxCode bTaxCode, @Amount bDollar, @TaxBasis bDollar, @TaxAmount bDollar,
   	@RetgPct bPct, @Retainage bDollar, @DiscOffered bDollar, @DiscTaken bDollar,
   	@ApplyMth bMonth, @ApplyTrans bTrans, @ApplyLine smallint,
   	@JCCo bCompany, @Job bJob, @JobStatus tinyint, @PhaseGroup bGroup, @Phase bPhase, @Dept bDept, @CostType bJCCType,
   	@EMCo bCompany, @Equipment bEquip,
   	@oldTransTypeLine char(1),@oldRecType tinyint, @oldLineType char, @oldGLCo bCompany, @oldGLAcct bGLAcct,
   	@oldDescription bDesc, @oldTaxGroup bGroup, @oldTaxCode bTaxCode,
   	@oldAmount bDollar, @oldTaxBasis bDollar, @oldTaxAmount bDollar, @oldRetainage bDollar, @oldDiscTaken bDollar,
   	@oldApplyMth bMonth, @oldApplyTrans bTrans, @oldApplyLine smallint,
   	@oldJCCo bCompany, @oldJob bJob, @oldJobStatus tinyint, @oldPhaseGroup  bGroup, @oldPhase  bPhase, @oldDept bDept, @oldCostType bJCCType,
   	@oldEMCo bCompany, @oldEquipment bEquip
   
declare @ARGLCo bCompany, @CMGLCo bCompany, @CMGLCash bGLAcct, @PostGLCo bCompany, @PostGLAcct bGLAcct,
   	@oldARGLCo bCompany, @HQTXGLAcct bGLAcct, @oldHQTXGLAcct bGLAcct,  @oldCMGLCo bCompany, @oldCMGLCash bGLAcct,
   	@oldPostGLCo bCompany, @oldPostGLAcct bGLAcct
   
   
/* START PROCESSING */
/* read Batch Header */
select @TransType=TransType, @ARTrans=ARTrans, @CheckNo=CheckNo,   @Source=Source, @ARTransType=ARTransType,
   	 @TransDate=TransDate, @CMCo=CMCo, @CMAcct=CMAcct, @CreditAmt=CreditAmt, @oldTransDate=oldTransDate,
   	 @oldCMCo=oldCMCo, @oldCMAcct=oldCMAcct, @oldCheckNo=oldCheckNo
from bARBH 
where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and BatchSeq = @BatchSeq
   
/* get the ARCo */
/*select @ARGLCo=GLCo  
from bARCO 
where ARCo=@ARCo
if @@rowcount=0
   begin
   select @errortext = 'Seq ' + convert (varchar(6),@BatchSeq) + ' - ARCo:' + convert(varchar(3),@ARCo) +': is invalid'
   exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
   if @rcode <> 0 goto bspexit
   End
*/
   
/***************************************/
/* AR Line Batch loop for validation   */
/***************************************/

select @ARLine=Min(ARLine) 
from bARBL
where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and BatchSeq=@BatchSeq
while @ARLine is not null
	begin
	select @TransTypeLine= TransType, @ARTrans=ARTrans , @RecType= RecType,
   		@LineType=LineType, @Description= Description, @GLCo=GLCo, @GLAcct=GLAcct,
   		@TaxGroup=TaxGroup,@TaxCode= TaxCode,@Amount=IsNull(Amount,0),@TaxBasis=IsNull(TaxBasis,0),
   		@TaxAmount=IsNull(TaxAmount,0),@RetgPct=RetgPct,@Retainage=IsNull(Retainage,0),
   		@DiscTaken=IsNull(DiscTaken,0),@ApplyMth=ApplyMth, @ApplyTrans=ApplyTrans, @ApplyLine= ApplyLine,
   		@JCCo= JCCo,@Job=Job, @PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType,
   		@Equipment = Equipment,
   		--- old values
   		@oldRecType=oldRecType,@oldLineType=oldLineType, @oldDescription= oldDescription,
   		@oldGLCo=oldGLCo, @oldGLAcct=oldGLAcct,@oldTaxGroup=oldTaxGroup,@oldTaxCode= oldTaxCode,
   		@oldAmount=IsNull(oldAmount,0),@oldTaxBasis=IsNull(oldTaxBasis,0),@oldTaxAmount=IsNull(oldTaxAmount,0),
   		@oldRetainage=IsNull(oldRetainage,0), @oldDiscTaken=IsNull(oldDiscTaken,0),
   		@oldApplyMth=oldApplyMth, @oldApplyTrans=oldApplyTrans, @oldApplyLine=oldApplyLine,
   		@oldJCCo=oldJCCo, @oldJob=oldJob, @oldPhaseGroup = oldPhaseGroup, @oldPhase = oldPhase, @oldCostType = oldCostType,
   		@oldEMCo=oldEMCo,@oldEquipment=oldEquipment
	from bARBL
	where Co = @ARCo and Mth = @Mth and BatchId=@BatchId and BatchSeq=@BatchSeq and ARLine=@ARLine
   
	select @errorstart = 'Seq ' + convert (varchar(6),@BatchSeq) + ' Line ' + convert(varchar(6),@ARLine)+ ' '
   
	---- validate transactions action
	if @TransTypeLine<>'A' and @TransTypeLine <>'C' and @TransTypeLine <>'D'
		begin
		select @errortext = @errorstart + ' - Invalid transaction type, must be A, C, or D.'
		exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		End
   
	/* get the accounts for the cash management co */
	select @CMGLCo=GLCo, @CMGLCash=GLAcct
	from bCMAC
	where CMCo=@CMCo and CMAcct=@CMAcct
	if @@rowcount=0
		begin
		select @errortext = @errorstart + ' - CM Acct:' + isnull(convert(varchar(3),@CMAcct),'') +': is invalid'
		exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end

	/* If TaxAmount exists in the batch, so must a TaxCode */
	if isnull(@TaxAmount, 0) <> 0 and @TaxCode is null
		begin
		select @errortext = @errorstart + ' - Orig Trans Mth  ' + isnull(Convert(varchar(12),@ApplyMth),'') + ' - Orig Trans# ' + 
		convert (varchar(8),@ApplyTrans) +  ' - Line ' + isnull(convert(varchar(6),@ApplyLine),'') + 
		'  must contain a TaxCode for this Payment.'
		exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end
   
	/* Validate Tax Group if there is a tax code - @TaxGroup will come from the following
	  sources: 	ARCO.GLCo	If No JCCo and No ECCo has been entered.
				JCCo		If ReImbursement is Job related.
				ECCo		If ReImbursement is Equipment related. 

	  TaxCode F4 Lookup and Validation are both based on TaxGroup.  In effect, we are
	  validating the Revenue, Job, or Equipment company along with a valid TaxGroup and
	  TaxCode. */
	if @TaxCode is not null
		begin
		select count(*) from bHQCO where HQCo = @GLCo  and TaxGroup = @TaxGroup 
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Company: ' + isnull(convert(varchar(10),@GLCo),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @TaxGroup),'') +': is invalid'
			exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		end
   
	/* Validate TaxCode by getting the accounts for the tax code  - Having reached here
	   the Company, TaxGroup and TaxCode are a match and we may proceed to retrieve
	   a valid Tax Account for this particular Company. */
	if @TaxCode is not null
		begin
		select @HQTXGLAcct = GLAcct 
		from bHQTX 
		where TaxGroup = @TaxGroup and TaxCode = @TaxCode
		if @@rowcount=0
			begin
			select @errortext = @errorstart + ' - TaxCode: ' + isnull(@TaxCode,'') +': is invalid'
			exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		end /* tax code validation*/
   	
	if @TransTypeLine in ('C','D') /* for deletes and changes */
		begin	/* begin Change/Del Loop */
		/* get the accounts for the cash management co */
		select @oldCMGLCo=GLCo, @oldCMGLCash=GLAcct
		from bCMAC
		where CMCo=@oldCMCo and CMAcct=@oldCMAcct
		if @@rowcount=0
			begin
			select @errortext = @errorstart +
				 ' - old CM Acct:' + isnull(convert(varchar(3),@oldCMAcct),'') +': is invalid'
			exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
   
		if @oldTaxCode is not null
			begin
       		select @oldHQTXGLAcct = GLAcct 
   			from bHQTX 
   			where TaxGroup = @oldTaxGroup and TaxCode = @oldTaxCode
   			if @@rowcount=0
   	    		begin
   	    		select @errortext = @errorstart + ' - Old TaxCode: ' + isnull(@oldTaxCode,'') +': is invalid'
   	    		exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
   	    		if @rcode <> 0 goto bspexit
   	    		end
   			end
   		
   		if @LineType = 'J'
   			begin
   			select @JobStatus = JobStatus
   			from bJCJM with (nolock)
   			where JCCo = @JCCo and Job = @Job
   			
   			if @JobStatus = 3
   				begin
 				/* Get Department:  First from Job/Phase Contract Item, and if missing then from Contract Master. */
				--JCJP: JCCo, Job, PhaseGroup, Phase
				select @Dept = i.Department
				from bJCCI i with (nolock)
				join bJCJP p with (nolock) on p.JCCo = i.JCCo and p.Contract = i.Contract and p.Item = i.Item
				where p.JCCo = @JCCo and p.Job = @Job and p.PhaseGroup = @PhaseGroup and p.Phase = @Phase
				if @Dept is null
					begin
					select @Dept = m.Department
					from bJCCM m with (nolock)
					join bJCJP p with (nolock) on p.JCCo = m.JCCo and p.Contract = m.Contract
					where p.JCCo = @JCCo and p.Job = @Job and p.PhaseGroup = @PhaseGroup and p.Phase = @Phase
					if @Dept is null
						begin
						select @errortext = @errorstart + ' - Department missing from Contract and Item.  Cannot determine Closed WIP Account. '
           				exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
           				if @rcode <> 0 goto bspexit
						end
					end

				if @Dept is not null
					begin
					/* Get Closed WIP Account */
					select @GLAcct = ClosedExpAcct
					from bJCDO with (nolock) 
					where JCCo = @JCCo and Department = @Dept and Phase = @Phase and PhaseGroup = @PhaseGroup
					if @GLAcct is null
						begin
						select @GLAcct = ClosedExpAcct
						from bJCDC with (nolock)
						where JCCo = @JCCo and Department = @Dept and CostType = @CostType and PhaseGroup = @PhaseGroup
						if @GLAcct is null
							begin
							select @errortext = @errorstart + ' - Closed WIP Account missing from Department CostType and Phase Overrides. '
           					exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
           					if @rcode <> 0 goto bspexit
							end
						end
					end  				
   				end
   			end
   				
   		if @oldLineType = 'J'
   			begin
   			select @oldJobStatus = JobStatus
   			from bJCJM with (nolock)
   			where JCCo = @oldJCCo and Job = @oldJob
   			
   			if @oldJobStatus = 3
   				begin
 				/* Get old Department:  First from Job/Phase Contract Item, and if missing then from Contract Master. */
				--JCJP: JCCo, Job, PhaseGroup, Phase
				select @oldDept = i.Department
				from bJCCI i with (nolock)
				join bJCJP p with (nolock) on p.JCCo = i.JCCo and p.Contract = i.Contract and p.Item = i.Item
				where p.JCCo = @oldJCCo and p.Job = @oldJob and p.PhaseGroup = @oldPhaseGroup and p.Phase = @oldPhase
				if @oldDept is null
					begin
					select @oldDept = m.Department
					from bJCCM m with (nolock)
					join bJCJP p with (nolock) on p.JCCo = m.JCCo and p.Contract = m.Contract
					where p.JCCo = @oldJCCo and p.Job = @oldJob and p.PhaseGroup = @oldPhaseGroup and p.Phase = @oldPhase
					if @oldDept is null
						begin
						select @errortext = @errorstart + ' - Department missing from old Contract and Item.  Cannot determine Closed WIP Account. '
           				exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
           				if @rcode <> 0 goto bspexit
						end
					end

				if @oldDept is not null
					begin
					/* Get Closed WIP Account */
					select @oldGLAcct = ClosedExpAcct
					from bJCDO with (nolock) 
					where JCCo = @oldJCCo and Department = @oldDept and Phase = @oldPhase and PhaseGroup = @oldPhaseGroup
					if @oldGLAcct is null
						begin
						select @oldGLAcct = ClosedExpAcct
						from bJCDC with (nolock)
						where JCCo = @oldJCCo and Department = @oldDept and CostType = @oldCostType and PhaseGroup = @oldPhaseGroup
						if @oldGLAcct is null
							begin
							select @errortext = @errorstart + ' - Old transaction Closed WIP Account missing from Department CostType and Phase Overrides. '
           					exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
           					if @rcode <> 0 goto bspexit
							end
						end
					end  				
   				end
   			end
		end		/* end Change/Del Loop */
   
	/* Begin GL Processing */
	select @i=1, @InterCompany = 4 /*set first intercompany account */
	while @i<=7
   		BEGIN  -- GLUpdate Begin
   
		/*Validate GL Accounts*/
		/* spin through each type of GL account, check it and write GL Amount */
   
		/****** new values *****/
		select @PostAmount=0, @oldPostAmount=0, @PostGLCo=null, @oldPostGLCo=null,
   			@compareICamt=0, @compareIColdamt=0, @chksubtype = 'N'
   
		/*  credit Expense Acct on refunds / credit Rev Acct on overcounter sales */
		if @i=1 
   			begin
   			select @PostGLCo=@GLCo, @PostGLAcct=@GLAcct, @PostAmount=-(IsNull(@Amount,0)-IsNull(@TaxAmount,0)),
				@oldPostGLCo=@oldGLCo, @oldPostGLAcct=@oldGLAcct, @oldPostAmount=(IsNull(@oldAmount,0)-IsNull(@oldTaxAmount,0)), 
   				@errdetail=' GL Acct'
   
   			/* Need to declare proper GLAcct SubType */
   			if @LineType = 'J' select @chksubtype = 'J'
   			if @LineType = 'E' select @chksubtype = 'E'
   			end
   
		/* credit tax Account - Typically only on 'O'- other, like overcounter sales */
		if @i=2
   			begin
         	select @PostGLCo=@GLCo, @PostGLAcct=@HQTXGLAcct, @PostAmount=-(IsNull(@TaxAmount,0)), 
				@oldPostGLCo=@oldGLCo, @oldPostGLAcct = @oldHQTXGLAcct, @oldPostAmount=IsNull(@oldTaxAmount,0),
   				@errdetail=' AR Tax GLAcct'
         	end
   
		/* debit cash account */
		if @i=3 
   			begin
   			select @PostGLCo=@CMGLCo, @PostGLAcct=@CMGLCash, @PostAmount=IsNull(@Amount,0),
           		@oldPostGLCo=@oldCMGLCo, @oldPostGLAcct=@oldCMGLCash, @oldPostAmount=-(IsNull(@oldAmount,0)), 
   				@errdetail=' Cash GLAcct'
   
   			/* Need to declare proper GLAcct SubType */
   			select @chksubtype = 'C'
   			end
   
   		/* If in 'Add' or 'Delete' mode and ARGL Company is the Same as the GLCo Company then
   		   skip all intercompany processing completely. */
   		if @i >= @InterCompany and @TransTypeLine in ('A', 'D') and @CMGLCo = @GLCo
   			begin
   			select @i = 7
   			goto GLUpdateEnd
   			end
   
   		/* Cross company requires 4 stages to accomodate 'C'hange mode as well as 'A'dd and 'D'elete */
   
		/* cross company part I  --  InterCompany Payables GLCo and GLAcct, retrieve OLD values */
   XCompany4:
		if @i=4 
     	  	begin
   			if @TransTypeLine = 'A' and @CMGLCo <> @GLCo goto XCompany5	-- There is no Old Inter-APGLCo
     	  	if @TransTypeLine = 'C' and @oldCMGLCo = @oldGLCo goto XCompany5	-- There is no Old Inter-APGLCo
   			select @oldPostGLCo = APGLCo, @oldPostGLAcct = APGLAcct, 
   				@oldPostAmount = (isnull(@oldAmount,0)), 
   				@compareICamt = (isnull(@Amount,0)),
				@errdetail='XREF GL Acct'
     	  	from bGLIA
         	where ARGLCo = @oldGLCo and APGLCo = @oldCMGLCo
   
    	  	if @@rowcount = 0
           		begin
           		select @errortext = 'Invalid cross company entry in GLIA. Must have Old PayableGLCo = '
            		+ isnull(convert(varchar(10),@oldCMGLCo),'') + ' - ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
           		end
   			end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @GLCo = @oldGLCo
   			and @CMGLCo = @oldCMGLCo select @oldPostAmount = 0
   
		/* cross company part II  --  InterCompany Payables GLCo and GLAcct, retrieve NEW values */
   XCompany5:
		if @i=5 	
     	  	begin
   			if @TransTypeLine = 'C' and @CMGLCo = @GLCo goto XCompany6	-- There is no NEW Inter-APGLCo
     	  	select @PostGLCo = APGLCo, @PostGLAcct = APGLAcct, 
     			@PostAmount = -(isnull(@Amount,0)), 
   				@compareIColdamt = -(isnull(@oldAmount,0)),
				@errdetail='XREF GL Acct'
     	  	from bGLIA
         	where ARGLCo = @GLCo and APGLCo= @CMGLCo
   
    	  	if @@rowcount = 0
           		begin
           		select @errortext = 'Invalid cross company entry in GLIA. Must have New PayableGLCo = '
            		+ isnull(convert(varchar(10),@CMGLCo),'') + ' - ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
           		end
         	end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @GLCo = @oldGLCo
   			and @CMGLCo = @oldCMGLCo select @PostAmount = 0
   
		/* cross company part III  --  InterCompany Receivables GLCo and GLAcct, retrieve OLD values */
   XCompany6:
		if @i=6 
     	  	begin
   			if @TransTypeLine = 'A' and @CMGLCo <> @GLCo goto XCompany7	-- There is no Old Inter-ARGLCo
     	  	if @TransTypeLine = 'C' and @oldCMGLCo = @oldGLCo goto XCompany7	-- There is no Old Inter-ARGLCo  	  	
   			select @oldPostGLCo = ARGLCo, @oldPostGLAcct = ARGLAcct,
               	@oldPostAmount = -(isnull(@oldAmount,0)), 
   				@compareICamt = -(isnull(@Amount,0)),
				@errdetail = 'XREF GL Acct'
     	  	from bGLIA
         	where ARGLCo = @oldGLCo and APGLCo = @oldCMGLCo  
   
         	if @@rowcount = 0
           		begin
           		select @errmsg = 'Invalid cross company entry in GLIA. Must have Old ReceivableGLCo = '
            		+ isnull(convert(varchar(10),@oldGLCo),'') + ' -  ' + isnull(@errmsg,'')
     			exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
           		end
     	  	end
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @oldPostAmount = @compareICamt and @GLCo = @oldGLCo
   			and @CMGLCo = @oldCMGLCo select @oldPostAmount = 0
   
		/* cross company part IV  --  InterCompany Receivables GLCo and GLAcct, retrieve NEW values */
   XCompany7:    
   		if @i=7 
     	  	begin
   			if @TransTypeLine = 'C' and @CMGLCo = @GLCo goto ARBAUpdate	-- There is no NEW Inter-ARGLCo
   			select @PostGLCo = ARGLCo, @PostGLAcct = ARGLAcct, 
     			@PostAmount = (isnull(@Amount,0)), 
   				@compareIColdamt = (isnull(@oldAmount,0)),
				@errdetail = 'XREF GL Acct'
     	  	from bGLIA
         	where ARGLCo = @GLCo and APGLCo= @CMGLCo
   
         	if @@rowcount = 0
           		begin
           		select @errmsg = 'Invalid cross company entry in GLIA. Must have New ReceivableGLCo = '
            		+ isnull(convert(varchar(10),@GLCo),'') + ' -  ' + isnull(@errmsg,'')
     	    	exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
           		end
     	  	end  
   
   		/* Skip, do not accumulate Intercompany values for lines whose amounts have
   		not changed unless the Intercompany itself has changed. This is evaluated 
   		separately from NON-Intercompany to avoid doubling amounts. */
   		if @TransTypeLine = 'C' and @PostAmount = @compareIColdamt and @GLCo = @oldGLCo
   			and @CMGLCo = @oldCMGLCo select @PostAmount = 0
   --
      	/* dont create GL if old and new are the same */	
      	if @TransTypeLine='C' and @PostAmount=-IsNull(@oldPostAmount,0) and @PostGLCo=@oldPostGLCo and @PostGLAcct=@oldPostGLAcct
      	goto GLUpdateEnd
   
   ARBAUpdate:
		/*********  This 1st Update/Insert relates to OLD values during Change and Delete Modes *********/
   
		/* if intercompany then try to update the record so there is only one record per transfer */
		if @i>=@InterCompany and @TransTypeLine <> 'A'  
         	begin
         	update bARBA 
   			set Amount = Amount + isnull(@oldPostAmount,0)
         	where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and BatchSeq=0 and ARLine=@oldPostGLCo and OldNew = 0   /* yes we are using ARLine for the Xcompany */
   				and GLAcct=@oldPostGLAcct
         	if @@rowcount=1 select @oldPostAmount=0  /* set Amount to zero so we dont re-add the record*/
         	end
   
   		/* if not intercompany then update a record if GLAccts are the same. */
   		if @i < @InterCompany and @TransTypeLine <> 'A'
   			begin
   			update bARBA
   			set Amount=Amount + isnull(@oldPostAmount,0)
     		where Co = @ARCo and Mth = @Mth and BatchId = @BatchId and GLCo = @oldPostGLCo
      			and GLAcct = @oldPostGLAcct and BatchSeq = @BatchSeq and ARLine = @ARLine
   			and OldNew = 0
   			if @@rowcount=1 select @oldPostAmount=0	/* set Amount to zero so we dont't re-add the record */
   			end
   
		/* For posting OLD values to all Accounts i=1 thru i=7 */
		if IsNull(@oldPostAmount,0) <> 0 and @TransTypeLine <> 'A' 
           begin
           exec @rcode = bspGLACfPostable @oldPostGLCo, @oldPostGLAcct, @chksubtype, @errmsg output
           if @rcode <> 0
           		begin
				select @errortext = @errorstart + '- old ' + @errdetail +' -: ' + @oldPostGLAcct +': '+ @errmsg
				exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
           else
           		begin
           		insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct, OldNew, BatchSeq, ARTrans, 
   					ARLine, ARTransType, CheckNo, Job, Equipment, ActDate, Description, 
   					Amount)
            	values(@ARCo, @Mth, @BatchId, @oldPostGLCo, @oldPostGLAcct, 0,
   		    		case when @i<@InterCompany then @BatchSeq else 0 end,
   		    		case when @i<@InterCompany then @ARTrans else 0 end,
   		   			case when @i<@InterCompany then @ARLine else @oldPostGLCo end,
   		    		case when @i<@InterCompany then @ARTransType else 'X' end,
   		     		case when @i<@InterCompany then @oldCheckNo else null end,
   		     		case when @i<@InterCompany then @oldJob else null end,
   		     		case when @i<@InterCompany then @oldEquipment else null end,
                 	@TransDate,
					case when @i<@InterCompany then @oldDescription else 'Inter-Company Transfer' end,
   -- Issue 20074              	case when @i<@InterCompany then case when @i = 3 then 'Cash Account' else @oldDescription end
   -- Issue 20074                   		else 'Inter-Company Transfer' end,
                 	@oldPostAmount)
   
				if @@rowcount = 0
                   	begin
                   	select @errmsg = @errorstart + ' Unable to add AR GL audit - ' + isnull(@errmsg,''), @rcode = 1
                   	GoTo bspexit
                   	end
          		end
       		end
   
       /*********  This 2nd Update/Insert relates to NEW values during Add and Change Modes *********/
   
       /* if intercompany then try to update the record so there is only one record per transfer */
       if @i >= @InterCompany and @TransTypeLine <> 'D'
			begin
			update bARBA
			set Amount=Amount + isnull(@PostAmount,0)
			where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and BatchSeq=0 and ARLine=@PostGLCo and OldNew = 1	/* yes we are using ARLine for the Xcompany */
           		and GLAcct = @PostGLAcct
   			if @@rowcount=1 select @PostAmount=0 	/* set Amount to zero so we don't re-add the record*/
			end
   
   		/* if not intercompany then update a record if GLAccts are the same. */
   		if @i < @InterCompany and @TransTypeLine <> 'D'
   			begin
   			update bARBA
   			set Amount=Amount + IsNull(@PostAmount,0)
     		where Co = @ARCo and Mth = @Mth and BatchId = @BatchId and GLCo = @PostGLCo
      			and GLAcct = @PostGLAcct and BatchSeq = @BatchSeq and ARLine = @ARLine
   				and OldNew = 1
   			if @@rowcount=1 select @PostAmount=0	/* set Amount to zero so we dont't re-add the record */
   			end 
   
		/* For posting NEW values to all Accounts i=1 thru i=7 */
		if IsNull(@PostAmount,0) <> 0 and (@TransTypeLine <> 'D') 
       		begin
			exec @rcode = bspGLACfPostable @PostGLCo, @PostGLAcct, @chksubtype, @errmsg output
			if @rcode <> 0
           		begin
				select @errortext = @errorstart + '- ' + @errdetail +' -: ' + @PostGLAcct +': '+ @errmsg
				exec @rcode = bspHQBEInsert @ARCo, @Mth, @BatchId, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   			else
           		begin
           		insert into bARBA(Co, Mth, BatchId, GLCo, GLAcct,OldNew, BatchSeq, ARTrans,
   					ARLine, ARTransType, CheckNo, Job, Equipment, ActDate, Description, Amount)
          		values(@ARCo, @Mth, @BatchId, @PostGLCo, @PostGLAcct, 1,
           			case when @i<@InterCompany then @BatchSeq else 0 end,
           			case when @i<@InterCompany then @ARTrans else 0 end,
           			case when @i<@InterCompany then @ARLine else @PostGLCo end,
           			case when @i<@InterCompany then @ARTransType else 'X' end,
           			case when @i<@InterCompany then @CheckNo else null end,
           			case when @i<@InterCompany then @Job else null end,
           			case when @i<@InterCompany then @Equipment else null end,
           			@TransDate,
   	      			case when @i<@InterCompany then @Description else 'Inter-Company Transfer' end,
   -- Issue 20074      		case when @i<@InterCompany then  case when @i = 3 then 'Cash Account' else @Description end
   -- Issue 20074       			else 'Inter-Company Transfer' end,
           			@PostAmount)
   
           		if @@rowcount = 0
               		begin
               		select @errmsg =  @errorstart + ' Unable to add AR GL audit - ' + isnull(@errmsg,''), @rcode = 1
               		GoTo bspexit
               		end
          		end
       		end
   
   GLUpdateEnd:
       /* get next GL record */
       select @i=@i+1, @errmsg=''
       END 	-- GLUpdate Begin
   
   /*****************/
   /* get next line */
   /*****************/
   select @ARLine=Min(ARLine) 
   from bARBL
   where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and BatchSeq=@BatchSeq and ARLine>@ARLine
   END -- NEXT AR LINE
   
bspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH1_ValMiscCashGL]'
return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValMiscCashGL] TO [public]
GO
