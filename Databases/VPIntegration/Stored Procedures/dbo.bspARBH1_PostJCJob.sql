SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_PostJCJob    Script Date: 8/28/99 9:36:04 AM ******/
   CREATE procedure [dbo].[bspARBH1_PostJCJob]
   /***********************************************************
   * CREATED BY  : JRE 9/15/97
   * MODIFIED By : bc 06/30/99
   *		gh 11/29/00 Corrected HQTCNextTrans call to pass @JCCO not @ARCO
   *		TJL 08/09/02:  Issue #15923, Fix failure when deleting multiple MiscRec Seq
   *		TJL 11/13/02:  Issue #15923, Rewrite - Fix updates to JCCD, particularily to 'Actual..'
   *		TJL 04/29/04:  Issue #24472, Set JCTransType = JC not AR,  Add 'with (nolock)
   *
   * USAGE:
   *   Posts a validated batch of bARBJ JC Amounts and deletes successfully posted bARBJ rows
   *     Though this runs from ARBHPost_Cash, the only time bARBJ will contain records is if
   *	  a MiscCashReceipt, Job type sequence exists.
   *
   *
   * INPUT PARAMETERS
   *   ARCo        AR Co
   *   Month       Month of batch
   *   BatchId     Batch ID to validate
   *
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   
   (@ARCo bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null, @Source bSource,
   	@errmsg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int, @tablename char(20), @JCInterface tinyint, @JCTrans bTrans
   
   declare @ARTrans bTrans, @ARLine smallint, @OldNew tinyint, @BatchSeq int,
   	@JCCo bCompany, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @CT bJCCType,
    	@GLCo bCompany, @GLAcct bGLAcct, @ARBJopencursor int
   
   --	@CheckNo varchar(10), @ActDate bDate, @Description bDesc,
   --	@UM bUM, @JobUnits bUnits, @JobHours bHrs, @Amount bDollar,
   
   select @rcode=0, @ARBJopencursor = 0
   
   if @Source not in ('AR Receipt')
   	begin
   	select @errmsg = 'Invalid Source', @rcode = 1
   	goto bspexit
   	end
   
   select @JCInterface = JCInterface 
   from bARCO with (nolock)
   where ARCo=@ARCo
   
   if @JCInterface not in (0,1)
   	begin
   	select @errmsg = 'Invalid JC Interface level', @rcode = 1
   	goto bspexit
   	end
   
   /* check for date posted */
   if @DatePosted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   /* update JC using entries from bARBJ */
   /****** no update *****/
   if @JCInterface = 0	 /* no update */
       begin
       delete bARBJ 
   	where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId
       goto bspexit
       end
   
   /*****  update ******/
   if @JCInterface = 1	/* transaction line update */
   	begin	/* Begin JCInterface 1 Loop */
   	/* The relationship between the distribution table bARBJ and the transaction line
   	   update to bJCCD is always 1 to 1.  Therefore a standard cursor will work just 
   	   fine. */
   	declare bcARBJ cursor for
   	select ARCo, Mth, BatchId, JCCo, Job, Phase, CT, BatchSeq,
   		ARLine, GLCo, GLAcct, OldNew
   	from bARBJ with (nolock)
   	where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId
   
   	open bcARBJ
   	select @ARBJopencursor = 1
   
   JC_posting_loop:
   	fetch next from bcARBJ into @ARCo, @Mth, @BatchId, @JCCo, @Job, @Phase, @CT, @BatchSeq,
   		@ARLine, @GLCo, @GLAcct, @OldNew
   	while @@fetch_status = 0
       	begin	/* Begin JC Posting Loop */
   
   		/* begin transaction */
       	begin transaction
   
   		/* Get next available transaction # for JCCD */
      		select @tablename = 'bJCCD'
       	exec @JCTrans = bspHQTCNextTrans 'bJCCD', @JCCo, @Mth, @errmsg output
       	if @JCTrans = 0 goto JC_posting_error
   
   		/* insert JCCD record */
       	insert into bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
   			JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, ReversalStatus,
   			ActualHours, UM, ActualUnits, ActualCost, PerECM,
   			ActualUnitCost,
   			PostedUM, PostedUnits, PostedECM,
   			PostedUnitCost)
       	select JCCo, Mth, @JCTrans, Job, PhaseGroup, Phase, CT, @DatePosted, ActDate,
   			'JC', @Source, Description, BatchId, GLCo, GLAcct, 0,
   			ActualHours, ActualUM, ActualUnits, Amount, 'E',
   			case when ActualUnits <> 0 then -(Amount/ActualUnits) else 0 end,
   			UM, Units, 'E',
   			case when Units <> 0 then -(Amount/Units) else 0 end
   		from bARBJ with (nolock)
       	where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId and JCCo = @JCCo
   			and Job = @Job and Phase = @Phase and CT = @CT and BatchSeq=@BatchSeq
           	and ARLine=@ARLine and GLCo = @GLCo and GLAcct = @GLAcct and OldNew=@OldNew 
      		if @@rowcount = 0 goto JC_posting_error
   
   		/* delete ARBJ distribution record */
       	delete bARBJ
       	where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId and JCCo = @JCCo
   			and Job = @Job and Phase = @Phase and CT = @CT and BatchSeq=@BatchSeq
           	and ARLine=@ARLine and GLCo = @GLCo and GLAcct = @GLAcct and OldNew=@OldNew 
   		if @@rowcount = 0 goto JC_posting_error
   
   		/* Commit transaction - No errors have occurred */
      		commit transaction
       	goto JC_posting_loop
   
   	JC_posting_error:	/* Error occured within transaction - rollback any updates and continue */
       	rollback transaction
   
   		end		/* End JC Posting Loop */
   
   	end		/* Begin JCInterface 1 Loop */
   
   /* make sure JC Audit is empty */
   if exists(select 1 from bARBJ with (nolock) where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId)
   	begin
   	select @errmsg = 'Not all updates to JC were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   /* Close and deallocate cursor */
   if @ARBJopencursor = 1
   	begin
   	close bcARBJ
   	deallocate bcARBJ
   	end
   
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH1_PostJCJob]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_PostJCJob] TO [public]
GO
