SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValMiscCashJC    Script Date: 8/28/99 9:34:07 AM ******/
CREATE procedure [dbo].[bspARBH1_ValMiscCashJC]
/***********************************************************
* CREATED BY:   JRE 9/17/97
* MODIFIED By : bc 10/01/98
*		SR 07/09/02: Issue 17738-passing @PhaseGroup to bspJCVPHASE
*		TJL 08/08/02:  Issue #15923:  Modified Inputs to bspJCVPHASE & bspJCVCOSTTYPE Procs
*		TJL 11/13/02:  Issue #15923, Fix updates to JCCD, particularily to 'Actual..' 
*		GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*		TJL 07/20/09 - Issue #134874, When Job is Final Closed, Expense changes need to be posted to Closed WIP Accounts
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*
*
* USAGE:
* Adds entry in bARBJ for a selected batch - called from bspARBHVal_Cash when
*	the Batch Sequence ARBH.ARTransType = 'M' (Misc Cash sequence only)
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Job distributions added to
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
   
@ARCo bCompany, @Mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output
as

set nocount on

declare @errortext varchar(255),  @errorstart varchar(50), @rcode int,@errdetail varchar(60),
   	@PostAmount bDollar, @oldPostAmount bDollar,@i tinyint, @OldNew tinyint,@TaxPhase bPhase,
   	@TaxCostType bJCCType, @SeperateTax bYN,@PostTax bDollar, @FirstProcess int, 
   	@LastProcess int, @postclosedjobs varchar(1), @JobStatus tinyint, @TaxAcct bGLAcct, 
   	@CostTypeAbbrev varchar(3), @TaxCostTypeAbbrev varchar(3), 
   	@ActualUM bUM, @JCCTTrackHours bYN, @postsoftclosedjobs varchar(1)
   
/* Declare AR Header variables */
declare @TransType char(1), @ARTrans bTrans, @ARTransType char(1), @Source bSource,
   	@CheckNo char(10), @Description bDesc, @TransDate bDate, @ActDate bDate,
   	@oldCheckNo char(10), @oldDescription bDesc,@oldTransDate bDate
   
/* Declare AR Line variables */
declare @Co bCompany, @ARLine smallint, @TransTypeLine char,
   	@LineType char, @GLCo bCompany, @GLAcct bGLAcct, @TaxGroup bGroup,
   	@TaxCode bTaxCode, @Amount bDollar, @TaxBasis bDollar, @TaxAmount bDollar,
   	@RetgPct bPct, @Retainage bDollar,	@JCCo bCompany, @Job bJob, @PhaseGroup bGroup, 
   	@Phase bPhase, @Dept bDept, @CostType bJCCType, @UM bUM, @JobUnits bUnits, @JobHours bHrs,
   	@oldLineType char,@oldGLCo  bCompany, @oldGLAcct bGLAcct,@oldTaxGroup  bGroup, 
   	@oldTaxCode  bTaxCode, @oldAmount bDollar, @oldTaxBasis bDollar, @oldTaxAmount bDollar,
   	@oldRetgPct bPct, @oldRetainage bDollar,@oldJCCo bCompany, @oldJob bJob, 
   	@oldPhaseGroup  bGroup, @oldPhase  bPhase, @oldCostType bJCCType, @oldUM bUM, 
   	@oldJobUnits bUnits, @oldJobHours bHrs
   
select @rcode = 0
   
/* Get Header values for this batch sequence. */
select @TransType=TransType, @ARTrans=ARTrans, @CheckNo=CheckNo, @Source=Source, 
	@ARTransType=ARTransType, @TransDate=TransDate, @oldTransDate=oldTransDate
from bARBH 
where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq = @batchseq
   
/***************************************/
/* AR Line Batch loop for validation   */
/***************************************/
   
select @ARLine=Min(ARLine) 
from bARBL
where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq=@batchseq
   	and (Job is not null or oldJob is not null)
   
--- get next record
while @ARLine is not null
   	begin
   	select  @TransTypeLine= TransType, @ARTrans=ARTrans,
   		@LineType=LineType, @Description= Description,@GLCo=GLCo,@GLAcct=GLAcct,@TaxGroup=TaxGroup,
   		@TaxCode= TaxCode,@Amount=IsNull(-Amount,0),@TaxAmount=IsNull(-TaxAmount,0),
   		@JCCo= JCCo, @Job=Job,@PhaseGroup=PhaseGroup, @Phase=Phase, @CostType = CostType, @UM= UM,
   		@JobUnits= IsNull(-JobUnits,0),@JobHours=IsNull(-JobHours,0),
   	--- old values
   		@oldLineType=oldLineType, @oldDescription= oldDescription,@oldGLCo=oldGLCo,@oldGLAcct=oldGLAcct,@oldTaxGroup=oldTaxGroup,
   		@oldTaxCode= oldTaxCode, @oldAmount=IsNull(oldAmount,0),@oldTaxAmount=IsNull(oldTaxAmount,0),
   		@oldJCCo=oldJCCo, @oldJob=oldJob, @oldPhaseGroup=oldPhaseGroup,
   		@oldPhase=oldPhase, @oldCostType=oldCostType, @oldUM=oldUM, @oldJobUnits=IsNull(oldJobUnits,0),
   		@oldJobHours=IsNull(oldJobHours,0)
   	from bARBL
   	where Co = @ARCo and Mth = @Mth and BatchId=@batchid and BatchSeq=@batchseq 
   		and ARLine=@ARLine and (Job is not null or oldJob is not null)
 
   	select @errorstart = 'Seq ' + convert (varchar(6),@batchseq) + ' Line ' + convert(varchar(6),@ARLine)+ ' '
   
   	/* loop once for new transaction (0) and then for old (1) (not to be confused with the OldNew amount which is the opposite) */
   	/* if add then loop while 0 thru 0, if delete then loop 1 thru 1, if change then loop 0 thru 1 */
   	select @FirstProcess=case when @TransTypeLine='D' then 1 else 0 end,
       	@LastProcess=case when @TransTypeLine='A' then 0 else 1 end
   
   	select @i=@FirstProcess
   	while @i<=@LastProcess
   		begin
       	select @OldNew = 1
   		/* If this is a 'D'elete or 'C'hange transaction, get old values. */
       	if @i = 1
       	select @LineType=@oldLineType, @Description= @oldDescription,@TaxGroup=@oldTaxGroup, @OldNew = 0,
   			@TaxCode= @oldTaxCode, @Amount=IsNull(@oldAmount,0),@TaxAmount=IsNull(@oldTaxAmount,0),
   			@JCCo=@oldJCCo,  @Job=@oldJob, @PhaseGroup=@oldPhaseGroup,@Phase=@oldPhase, @CostType=@oldCostType,
   			@UM=@oldUM, @JobUnits=IsNull(@oldJobUnits,0),@JobHours=IsNull(@oldJobHours,0),
   			@GLCo=@oldGLCo, @GLAcct=@oldGLAcct
   
   		/* if this is not a line type (J) then skip over posting to JC */
   		if @LineType <> 'J' goto JCWhileLoop 
   
   		/* verify job and check post to closed jobs */
       	select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs,
				@JobStatus=JobStatus
   		from bJCCO
   		join bJCJM on bJCCO.JCCo=bJCJM.JCCo
   		where bJCCO.JCCo=@JCCo and bJCJM.JCCo=@JCCo and bJCJM.Job=@Job
   
       	if @@rowcount=0
           	begin
           	select @errortext = @errorstart + ' - Job:' + isnull(@Job,'') +': is invalid'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           	if @rcode <> 0 goto bspexit
           	End

		if @postsoftclosedjobs = 'N' and @JobStatus = 2
			begin
			select @errortext = @errorstart + ' - Job:' + isnull(@Job,'') +': is soft-closed, posting not allowed'
			exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

       	if @postclosedjobs = 'N' and @JobStatus = 3
           	begin
           	select @errortext = @errorstart + ' - Job:' + isnull(@Job,'') +': is hard-closed, posting not allowed'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           	if @rcode <> 0 goto bspexit
           	end
   
   		/* Get Closed WIP Account to post changes to when Job is Final Closed. 
			If Line TransType = A, not required because Line GL Account will be Closed WIP Account returned 
			from either Phase Overrides (JCDO) or CostTypes (JCDC) as setup in the Dept Master. */
		if (@TransTypeLine = 'D' or @TransTypeLine = 'C') and @JobStatus = 3
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
           			exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
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
           				exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           				if @rcode <> 0 goto bspexit
						end
					end
				end
			end
		
   /****************************************************************************************/
   	/* These Tax related operations are not valid for this procedure AT THIS TIME.  This 
   	   procedure will only be run if this is a MiscCashReceipt!.  Likewise this procedure
   	   relates only to a 'J'ob type MiscCashReceipt.  TaxCode, TaxBasis, TaxAmount fields
   	   are always disabled on a 'J' type CashReceipt.  The current business logic here is
   	   that Job related expenses and sales tax do not get broken out separately (except in
   	   some Inventory related cases) and that we are not going to go to that extent, AT
   	   THIS TIME, for job expense related refunds.  We are keeping it simple unless
   	   customer begin demanding otherwise. REM'D out for now. */
   	   
   		/* get the tax phase and group */
   		/*
       	if @TaxAmount<>0	-- TaxCodes/TaxAmounts will always be 0.00 for 'J' and 'E' DetailTypes
   			begin
   			select @TaxPhase=Phase, @TaxCostType=JCCostType, @TaxAcct=GLAcct 
   			from bHQTX
   			where TaxGroup=@TaxGroup and TaxCode=@TaxCode
   
   			if @@rowcount=0
   	        	begin
           		select @errortext = @errorstart + ' - TaxCode:' + @TaxCode +': is invalid.'
   	        	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
   
   	        	if @rcode <> 0 goto bspexit
   	        	end
   		*/
   			/* if no tax phase or costtype then use the phase or costtype as posted */
   		--	select @TaxPhase=IsNull(@TaxPhase,@Phase), @TaxCostType=IsNull(@TaxCostType,@CostType)
   
   			/* if tax phase & costtype is not same as posted then seperate the tax from the amount */
   		--	select @SeperateTax=case when @TaxPhase=@Phase and @TaxCostType=@CostType then 'N' else 'Y' end
   		--	end
   
   		/* set the posting amounts credit job expense */
   		/*
       	select @PostAmount=case @SeperateTax when 'N' then @Amount else (@Amount - @TaxAmount) end,
   	   		@PostTax=case @SeperateTax when 'N' then 0 else @TaxAmount end
   		*/
   /*****************************************************************************************/
   
   		/* set the posting amounts credit job expense */
   		select @PostAmount = @Amount, @PostTax = 0
   
   		/* dont post 0 amount */
       	if IsNull(@PostAmount,0)= 0 and IsNull(@JobUnits,0)= 0 and IsNull(@JobHours,0)= 0 goto JCTaxRecord
   
   		/* Begin Validation */
   
   		/* Get Actual Job values to determine Actual.. values to be posted to JCCD */
   		select @ActualUM = h.UM, @JCCTTrackHours = t.TrackHours
   		from bARBL l
   		join bJCCH h on h.JCCo = l.JCCo and h.Job = l.Job and h.PhaseGroup = l.PhaseGroup
   			and h.Phase = l.Phase and h.CostType = l.CostType
   		join bJCCT t on t.PhaseGroup = l.PhaseGroup and t.CostType = l.CostType
   		where l.Co = @ARCo and l.Mth = @Mth and l.BatchId = @batchid and l.BatchSeq = @batchseq
   			and (l.Job is not null or l.oldJob is not null) and l.ARLine = @ARLine
   
   		/* Validate Phase */
       	exec @rcode=bspJCVPHASE @JCCo, @Job, @Phase, @PhaseGroup, null,
   			null, null, null, null, null, null, null, null, @errmsg output
       	If @rcode<>0
           	begin
           	select @errortext = @errorstart + ' - Phase:' + isnull(@Phase,'') +': is invalid.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
   
           	if @rcode <> 0 goto bspexit
           	end
   
   		/* Validate CostType */
       	select @CostTypeAbbrev =convert(varchar(5),@CostType)
   
      		exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @Phase, @CostTypeAbbrev, null,
   			null,null,null,null,null,null,null,null,null,@errmsg output
       	if @rcode<>0
           	begin
           	select @errortext = @errorstart + ' - CostType:' + isnull(convert(varchar(3),@CostType),'') +': is invalid.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
   			if @rcode <> 0 goto bspexit
           	end
   
   		/* Validate Posted UM */
       	if IsNull(@JobUnits,0) <> 0
   			begin
   			exec @rcode=bspHQUMVal @UM, @errmsg output
   			if @rcode<>0
           		begin
           		select @errortext = @errorstart + ' - UM:' + isnull(@UM,'') +': is invalid.'
           		exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           		if @rcode <> 0 goto bspexit
           		end
   			end
   
   		/* Insert record into Job distribution table. */
		if @GLAcct is not null
			begin		
       		insert into bARBJ(ARCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, CT, BatchSeq, ARLine,
   				ARTrans, OldNew, CheckNo, ActDate, Description, GLCo, GLAcct, UM, Units, 
   				Hours, 
   				Amount, ActualUM, 
   				ActualUnits, 
   				ActualHours)
       		values(@ARCo, @Mth, @batchid, @JCCo, @Job, @PhaseGroup, @Phase, @CostType, @batchseq, @ARLine,
   				@ARTrans, @OldNew, @CheckNo, @TransDate, @Description, @GLCo, @GLAcct, @UM, @JobUnits, 
   				case when @JCCTTrackHours = 'Y' then @JobHours else 0 end, 
   				@PostAmount, @ActualUM,
   				case when @UM = @ActualUM then @JobUnits else 0 end,
   				case when @JCCTTrackHours = 'Y' then @JobHours else 0 end)
       		if @@rowcount = 0
   				begin
   				select @errmsg = @errorstart + ' Unable to add AR Job audit record', @rcode = 1
   				GoTo bspexit
   				End
			end
			
   	/****************************************************************************************/
   		/* These Tax related operations are not valid for this procedure AT THIS TIME.  This 
   		   procedure will only be run if this is a MiscCashReceipt!.  Likewise this procedure
   		   relates only to a 'J'ob type MiscCashReceipt.  TaxCode, TaxBasis, TaxAmount fields
   		   are always disabled on a 'J' type CashReceipt.  The current business logic here is
   		   that Job related expenses and sales tax do not get broken out separately (except in
   		   some Inventory related cases) and that we are not going to go to that extent, AT
   		   THIS TIME, for job expense related refunds.  We are keeping it simple unless
   		   customer begin demanding otherwise. REM'D out for now. */
   
   	JCTaxRecord:
   
   		/* dont post 0 amount */
       	--if IsNull(@PostTax,0)=0  goto JCWhileLoop /*JCUpdate_End*/
   
   		/* verify phase */
   		/*
       	exec @rcode=bspJCVPHASE @JCCo, @Job, @TaxPhase, @PhaseGroup, null,
   			null, null, null, null, null, null, null, null, @errmsg output
       	If @rcode <> 0
           	begin
           	select @errortext = @errorstart + ' - Tax Phase:' + @TaxPhase +': is invalid.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           	if @rcode <> 0 goto bspexit
           	end
   		*/
   
   		/* verify cost type */
   		/*
       	select @TaxCostTypeAbbrev =convert(varchar(5),@TaxCostType)
   
      		exec @rcode=bspJCVCOSTTYPE @JCCo, @Job, @PhaseGroup, @TaxPhase, @TaxCostTypeAbbrev, null,
   			null,null,null,null,null,null,null,null,null,@errmsg output
       	if @rcode <> 0
           	begin
           	select @errortext = @errorstart + ' - Tax CostType:' + str(@TaxCostType,3,0) +' is invalid.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @errmsg output
           	if @rcode <> 0 goto bspexit
           	end
   		*/
   
   		/* insert batch record */
   		/* If this is Tax Refund, what UM, Units, Hours, ActualUM, ActualUnits, ActualHours
   		   do you use?????? */
   		/*
       	insert into bARBJ(ARCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, CT, BatchSeq, ARLine,
   			ARTrans, OldNew, CheckNo, ActDate, Description, GLCo, GLAcct, Amount)
       	values(@ARCo, @Mth, @batchid, @JCCo, @Job, @PhaseGroup, @TaxPhase, @TaxCostType, @batchseq, @ARLine,
   			@ARTrans, @OldNew, @CheckNo, @TransDate, @Description, @GLCo, @TaxAcct, @PostTax)
   
       	if @@rowcount = 0
   			begin
   			select @errmsg = @errorstart + ' Unable to add AR Job audit record', @rcode = 1
   			GoTo bspexit
   			end
   		*/
   	/****************************************************************************************/
   
   	JCWhileLoop:
       	select @i = @i + 1
   
   		End  -- of @i while loop
   
JCUpdate_End:
	   
	---- get next line
	select @ARLine=Min(ARLine) 
	from bARBL
	where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq=@batchseq and ARLine > @ARLine
		and (Job is not null or oldJob is not null)
   
	End
   
bspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH1_ValMiscCashJC]'
return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValMiscCashJC] TO [public]
GO
