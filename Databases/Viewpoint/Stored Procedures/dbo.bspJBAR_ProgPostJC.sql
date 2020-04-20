SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_ProgPostJC]
   /***********************************************************
   * CREATED BY  : bc 10/27/99
   * MODIFIED By : TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *
   * USAGE:
   * Posts a validated batch of bJBJC JC Amounts
   * and deletes successfully posted bJBJC rows
   
   *
   * INPUT PARAMETERS
   *   JBCo        JB Co
   *   Month       Month of batch
   *   BatchId     Batch ID to validate
   
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   
   *   1   fail
   *****************************************************/
   
   (@jbco bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null, @Source bSource, @errmsg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int, @tablename char(20), @JCInterface tinyint, @JCTrans bTrans, @ActDate bDate, @opencursorJBJC int
   
   declare @JCCo bCompany, @Contract bContract, @Item bContractItem, @BatchSeq int, @ARTrans bTrans,
   	@ARLine smallint, @OldNew tinyint, @Invoice char(10),
   	@BilledUnits bUnits, @BilledTax bDollar, @BilledAmt bDollar, @RecvdAmt bDollar, @Retainage bDollar, @arco bCompany,
   	@JBTransType char(1)
   
   select @rcode=0
   
   if @Source not in ('JB')
    	begin
    	select @errmsg = 'Invalid Source', @rcode = 1
    	goto bspexit
    	end
   
   /* get the ARCo for this JB company out of JCCO */
   select @arco = ARCo
   from JCCO with (nolock)
   where JCCo = @jbco
   
   select @JCInterface = JCInterface
   from bARCO with (nolock)
   where ARCo=@arco
   
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
   
   /* update JC using entries from bJBJC */
   /****** no update *****/
   if @JCInterface = 0	 /* no update */
   	begin
   	delete bJBJC
   	where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId
   	goto bspexit
   	end
   
   /*****  update ******/
   /* JBJC validation */
   declare bcJBJC cursor local fast_forward for
   select JCCo, Contract, Item, BatchSeq, ARLine, OldNew, JBTransType
   from bJBJC
   where JBCo = @jbco and Mth = @Mth and BatchId=@BatchId
   
   /* open cursor for line */
   open bcJBJC
   
   /* set appropiate cursor flag */
   select @opencursorJBJC = 1
   
   /* read cursor lines */
   get_next_bcJBJC:
   fetch next
   from bcJBJC
   into @JCCo, @Contract, @Item, @BatchSeq, @ARLine, @OldNew, @JBTransType
   
   while (@@fetch_status = 0)
   	begin
      	begin transaction
   
      	/* get next available transaction # for JCID */
      	select @tablename = 'bJCID'
      	exec @JCTrans = bspHQTCNextTrans @tablename, @JCCo, @Mth, @errmsg output
      	if @JCTrans = 0 goto JC_posting_error
   
      	/* insert JCID record */
      	insert into bJCID (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,
       	Description,PostedDate,ActualDate,BilledUnits,BilledTax,BilledAmt,ReceivedAmt,CurrentRetainAmt,
        	BatchId,GLCo,GLTransAcct,ReversalStatus,ARCo,ARTrans,ARTransLine,ARInvoice)
      	select JCCo, @Mth, @JCTrans, Contract,Item,'JB',@Source,
      		Description, @DatePosted,ActDate, IsNull(BilledUnits,0), IsNull(BilledTax,0),
        	IsNull(BilledAmt,0),0,IsNull(Retainage,0),
         	@BatchId,GLCo,GLAcct,0,@arco,ARTrans,ARLine,Invoice
      	from bJBJC a with (nolock)
      	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and
        	a.JCCo = @JCCo and a.Contract = @Contract and a.Item = @Item and BatchSeq = @BatchSeq and
        	a.ARLine = @ARLine and a.OldNew = @OldNew and a.JBTransType = @JBTransType
   
      	if @@rowcount = 0 goto JC_posting_error
   
      	/* delete batch record */
      	delete bJBJC
      	where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId and BatchSeq = @BatchSeq and
            ARLine = @ARLine and OldNew = @OldNew and JBTransType = @JBTransType
   
      	/* commit trans */
      	commit transaction
      	goto JC_posting_loop
   
   JC_posting_error:	/* error occured within transaction - rollback any updates and continue */
      	rollback transaction
   
   JC_posting_loop:
      	/*** next line **/
      	goto get_next_bcJBJC
      	end /* JBJC Loop */
   
   
   /* make sure JC Audit is empty */
   if exists(select 1 from bJBJC with (nolock) where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId)
    	begin
    	select @errmsg = 'Not all updates to JC were posted - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
   
   close bcJBJC
   deallocate bcJBJC
   select @opencursorJBJC = 0
   
   bspexit:
   
   if @opencursorJBJC = 1
      	begin
      	close bcJBJC
      	deallocate bcJBJC
      	end
   
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspJBAR_ProgPostJC]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_ProgPostJC] TO [public]
GO
