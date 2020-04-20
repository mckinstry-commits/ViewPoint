SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCIBVal    Script Date: 8/28/99 9:36:21 AM ******/
   CREATE         procedure [dbo].[bspJCIBVal]
   /***********************************************************
    * CREATED BY: JM   4/22/97
    * MODIFIED By : JRE 6/22/98 GLAcct validation for old and oldReversal
    *			Replaced cursor with pseudo-cursor
    *               LM 3/30/99 changed sum(isnull... to isnull(sum...
    *               DANF 1/17/2000 correct old JCCI VAL passing in too many parameters.
    *               DANF 1/24/2000 corrected gl account debits and credits.
    *               DANF 04/06/02 - Added Inter Company postings.
    *               DANF 06/11/02 - Corrected GL Out of balanced check.
    *               DANF 09/23/02 - Corrected invalid to company on reversals. 18655
    *				 TV - 23061 added isnulls
    *				 DANF 05/24/05 - 28726 Correct validation of old contract.
    *				GF 05/05/2010 - issue #139178 posting to pending status not allowed
    *
    * USAGE:
    * Validates each entry in bJCIB for a selected batch - must be called
    * prior to posting the batch.
    *
    * After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
    * bHQBE (Batch Errors), and bJCIA (JC GL Batch) entries are deleted.
    *
    * Creates a cursor on bJCIB to validate each entry individually.
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    * Account distributions added to bJCIA
    *
    * Jrnl and GL Reference debit and credit totals must balance.
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    * INPUT PARAMETERS
    *   JCCo        JC Co
    *   Month       Month of batch
    *   BatchId     Batch ID to validate
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output
   as
   set nocount on
   
   declare @accttype char(1), @active bYN, @actdate bDate,	@balamt bDollar, @billedamt bDollar,
   	@billedunits bUnits, @contract bContract, @description bTransDesc, @dtactualdate bDate,
   	@dtbilledamt bDollar, @dtbilledunits bUnits, @dtcontract bContract, @dtdescription bTransDesc,
   	@dtglco bCompany, @dtgloffsetacct bGLAcct, @dtgltransacct bGLAcct, @dtitem bContractItem,
   	@dtjctranstype varchar(2), @dtreversalstatus tinyint, @errorstart varchar(50),
   	@errortext varchar(255), @fy bMonth, @glco bCompany, @gloffsetacct bGLAcct,
   	@glrevdetaildesc varchar(60), @glrevjournal bJrnl, @glrevlevel tinyint, @glrevoverride bYN,
   	@glrevsummarydesc varchar(30), @gltransacct bGLAcct, @inusebatchid bBatchID, @inuseby bVPUserName,
   	@item bContractItem, @itemtrans bTrans, @jcglco bCompany, @jctranstype varchar(2),
   	@lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @oldactdate bDate, @oldbilledamt bDollar,
   	@oldbilledunits bUnits,	@oldcontract bContract, @olddescription bTransDesc, @oldglco bCompany,
   	@oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @olditem bContractItem,
   	@oldjctranstype varchar(2), @oldreversalstatus tinyint, @opencursor tinyint, @rcode int,
   	@reversalstatus tinyint, @seq int, @source bSource, @status tinyint, @stmtdate bDate,
   	@subtype char(1), @tablename char(20),@transtype char(1), 
		@tojcco bCompany, @tojcglco bCompany, @toglrevdetaildesc varchar(60), @toglrevjournal bJrnl,
		@toglrevlevel tinyint, @toglrevoverride bYN,	@toglrevsummarydesc varchar(30),
		@intercoapglacct bGLAcct, @intercoarglacct bGLAcct,
		----#139178
		@ContractStatus tinyint, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)
   
   select @rcode = 0
   
   /* set open cursor flag to false */
   select @opencursor = 0
   
   /* validate HQ Batch */
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'JC RevAdj', 'JCIB', @errmsg output, @status output
   select @errmsg
   if @rcode <> 0
   	begin
       	select @errmsg = @errmsg, @rcode = 1
       	goto bspexit
      	end
   
   
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
   
/* get GL Company from JC Company */
select @jcglco = GLCo, @glrevlevel=GLRevLevel, @glrevoverride=GLRevOveride,
      @glrevjournal=GLRevJournal, @glrevdetaildesc=GLRevDetailDesc,
      @glrevsummarydesc=GLRevSummaryDesc,
      ----#139178
      @postclosedjobs = PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from dbo.bJCCO with (nolock) where JCCo = @co
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid JC Company #', @rcode = 1
	goto bspexit
	end
   
   /* validate GL Company and Month */
   select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
   
   	from dbo.bGLCO with (nolock) where GLCo = @jcglco
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid GL Company #' + isnull(convert(varchar(2),@jcglco),''), @rcode = 1
   	goto bspexit
   	end
   if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   	begin
   	select @errmsg = 'Not an open month', @rcode = 1
   	goto bspexit
   	end
   
   /* validate Fiscal Year */
   select @fy = FYEMO from dbo.bGLFY with (nolock)
   	where GLCo = @jcglco and @mth >= BeginMth and @mth <= FYEMO
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Must first add Fiscal Year', @rcode = 1
   	goto bspexit
   	end
   
   /* set HQ Batch status to 1 (validation in progress) */
   update dbo.bHQBC
   	set Status = 1
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* clear HQ Batch Errors */
   delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* clear GL Item Audit */
   delete dbo.bJCIA where JCCo = @co and Mth = @mth and BatchId = @batchid
   
   /*clear and refresh HQCC entries */
   delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   
   insert into dbo.bHQCC(Co, Mth, BatchId, GLCo)
        select distinct Co, Mth, BatchId, GLCo from bJCIB
          where Co=@co and Mth=@mth and BatchId=@batchid
   
   /* spin through JC Item Batch for validation */
   select @seq=Min(BatchSeq) from dbo.bJCIB  where Co = @co and Mth = @mth and BatchId = @batchid
   while @seq is not null
   begin
   select  @transtype=TransType, @itemtrans=ItemTrans, @contract=Contract,
   	@item=Item,@actdate=ActDate, @jctranstype=JCTransType, @description=Description,
   	@glco=GLCo, @gltransacct=GLTransAcct, @gloffsetacct=GLOffsetAcct,@reversalstatus=ReversalStatus,
   	@billedunits= BilledUnits, @billedamt=BilledAmt,@oldcontract=OldContract, @olditem=OldItem,
   	@oldactdate=OldActDate, @oldjctranstype=OldJCTransType, @olddescription=OldDescription,
   	@oldglco=OldGLCo,@oldgltransacct=OldGLTransAcct, @oldgloffsetacct=OldGLOffsetAcct,
   	@oldreversalstatus=OldReversalStatus, @oldbilledunits=OldBilledUnits, @oldbilledamt=OldBilledAmt,
       @tojcco = ToJCCo
   	from dbo.bJCIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
   
      /* validate JC Item Batch info for each entry */
      select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
       if isnull(@tojcco,'') = ''
           begin
           select @tojcco = @co
   
           update dbo.bJCIB
           Set ToJCCo = @tojcco
           where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
           end
   
      /* validate transaction type */
      if @transtype <> 'A' and @transtype <> 'C' and @transtype <> 'D'
         begin
          select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
          exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
          if @rcode <> 0 goto bspexit
         end
   
      /* validation specific to Add types */
      if @transtype = 'A'
         begin
          /* check JC Trans# */
   
          if @itemtrans is not null
    	  begin
   
   	   select @errortext = @errorstart + ' - (New) entries may not reference an Item Transaction #.'
 
   
   	   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   
   	   if @rcode <> 0 goto bspexit
   	  end
   
         /* all old values must be null */
          if @oldcontract is not null or @olditem is not null or
             @oldactdate is not null or @oldjctranstype is not null or @olddescription is not null or
             @oldglco is not null or @oldgltransacct is not null or @oldgloffsetacct is not null or
   	  @oldbilledunits is not null or @oldbilledamt is not null
   
    	  begin
   	   select @errortext = @errorstart + ' - Old information in batch must be null for Add entries.'
   	   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	   if @rcode<>0 goto bspexit
   	  end
          end
   
   
        select @tojcglco = @jcglco, @toglrevlevel = @glrevlevel, @toglrevoverride = @glrevoverride,
               @toglrevjournal = @glrevjournal, @toglrevdetaildesc = @glrevdetaildesc, 
               @toglrevsummarydesc = @glrevsummarydesc
   
      /* validation specific to Add and change types */
      if @transtype = 'A' or @transtype = 'C'
         begin
         /* validate Contract JC Transaction Type - AP, AR, JC, Etc...*/
         if @jctranstype <> 'AP' and @jctranstype <> 'AR' and @jctranstype <> 'JC' and
            @jctranstype <> 'PR' and @jctranstype <> 'MO' and @jctranstype <> 'EM' and
   		 @jctranstype <> 'CA' and @jctranstype <> 'IC'
    	 begin
   	  select @errortext = @errorstart + isnull(@jctranstype,'') + ' is an Invalid JCTransType for this batch.'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
   
         if @jctranstype = 'IC'
           begin
   		/* get GL Company from JC Company */
   		select @tojcglco = GLCo, @toglrevlevel=GLRevLevel, @toglrevoverride=GLRevOveride,
    	   	   @toglrevjournal=GLRevJournal, @toglrevdetaildesc=GLRevDetailDesc,
     	   	   @toglrevsummarydesc=GLRevSummaryDesc from bJCCO where JCCo = @tojcco
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Invalid To JC Company #', @rcode = 1
   			goto bspexit
   			end
   
   		/* validate GL Company and Month */
   		select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
   		from dbo.bGLCO with (nolock) where GLCo = @tojcglco
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Invalid GL Company #' + isnull(convert(varchar(2),@tojcglco),''), @rcode = 1
   			goto bspexit
   			end
   		if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   			begin
   			select @errmsg = 'Not an open month', @rcode = 1
   			goto bspexit
   			end
   
   		/* validate Fiscal Year */
   		select @fy = FYEMO from dbo.bGLFY with (nolock)
   		where GLCo = @tojcglco and @mth >= BeginMth and @mth <= FYEMO
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Must first add Fiscal Year', @rcode = 1
   			goto bspexit
   			end
   
           end
   	 end


/* validate contract */
select @ContractStatus = ContractStatus from dbo.bJCCM with (nolock) where JCCo=@tojcco and Contract = @contract
if @@rowcount = 0
	begin
	select @errortext = @errorstart + 'Contract ' + isnull(@contract,'') + ' - is invalid.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto SkipItemVal1   /* if invalid then skip item validation*/
   	end

----#139178
if @ContractStatus = 0
	begin
	select @errortext = @errorstart + 'Contract ' + isnull(@contract,'') + ' - is pending.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto SkipItemVal1   /* if invalid then skip item validation*/
	end

if @ContractStatus = 2 and @postsoftclosedjobs = 'N'
	begin
	select @errortext = @errorstart + 'Contract ' + isnull(@contract,'') + ' - is soft-closed and posting not allowed.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto SkipItemVal1   /* if invalid then skip item validation*/
	end

if @ContractStatus = 3 and @postclosedjobs = 'N'
	begin
	select @errortext = @errorstart + 'Contract ' + isnull(@contract,'') + ' - is hard-closed and posting not allowed.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto SkipItemVal1   /* if invalid then skip item validation*/
	end
----#139178
   	

/* validate item */
exec @rcode = dbo.bspJCCIVal @tojcco, @contract, @item, @msg=@errmsg output
if @rcode = 1
	begin
	select @errortext = @errorstart + isnull(convert(varchar(30),@item),'') + ' - ' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto SkipItemVal1   /* if invalid then skip item validation*/
	end


SkipItemVal1:
   
/*validate GLAccounts */
exec @rcode = dbo.bspGLACfPostable @glco, @gltransacct, 'J', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + 'Transaction GLAcct:' + isnull(@gltransacct,'') + ' ' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end
   
         /*Only validate Offset account if its not null */
         if not @gloffsetacct is null
   	begin
    	 exec @rcode = dbo.bspGLACfPostable @jcglco, @gloffsetacct, 'N', @errmsg output
   
   	 if @rcode <> 0
   	  begin
   	   select @errortext = @errorstart + 'Offset GLAcct:' + isnull(@gloffsetacct,'') + ' ' + isnull(@errmsg,'')
   	   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	   if @rcode <> 0 goto bspexit
       	  end
   	end
   
         /*if its a reversal transaction then  Offset acct can't be null */
   
         else
   	if @reversalstatus=1
   	begin
   	   select @errortext = @errorstart + 'You must have an offset account for reversal transactions! '
   	   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	   if @rcode <> 0 goto bspexit
   	end
   
          /*validate Reversal Status,must be 0, 1, 2, 3,  4 */
         if @reversalstatus<>0 and @reversalstatus<>1 and
            @reversalstatus<>2 and @reversalstatus<>3 and @reversalstatus<> 4
     	 begin
   	  select @errortext = @errorstart + 'reversal status:' + isnull(convert(char(2),@reversalstatus),'') + ' is invalid!'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
       	 end
   
        if @reversalstatus=4 and @transtype = 'C'
     	 begin
   	  select @errortext = @errorstart + 'cannot cancel reversal entry unless it is the original reversing entry.'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
       	 end
   
        if @reversalstatus=1 and @gloffsetacct is null
     	 begin
   	  select @errortext = @errorstart + 'reversal transactions must have an offset account! is invalid!'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
       	 end
   
   
       end
   
       /* validation specific for Change and Delete types */
     if @transtype = 'C' or @transtype = 'D'
        begin
        /* get existing values from JCID */
         select @dtcontract=Contract, @dtitem=Item, @dtactualdate=ActualDate, @dtjctranstype=@jctranstype,
                @dtdescription=Description, @dtglco=GLCo, @dtgltransacct=GLTransAcct, @dtgloffsetacct=GLOffsetAcct,
   
   	     @dtreversalstatus=ReversalStatus, @dtbilledunits=BilledUnits, @dtbilledamt=BilledAmt,
   	     @inusebatchid = InUseBatchId
   	from dbo.bJCID with (nolock) where JCCo = @tojcco and
   		Mth = @mth and
   		ItemTrans = @itemtrans
         if @@rowcount = 0
   	 begin
    	  select @errortext = @errorstart + ' - Missing JC Detail Transaction#:' + isnull(convert(char(3),@itemtrans),'')
    	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
             goto nextrec
   	 end
   
   	/* check In Use Batch info */
          if @inusebatchid <> @batchid
   	  begin
   	   select @errortext = @errorstart + ' - Existing Detail Transaction has not been assigned to this batch.'
   	   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   
   	   if @rcode <> 0 goto bspexit
   	  end
   
   
   	/* make sure old values in batch match existing values in detail */
        	if @dtcontract<>@oldcontract or @dtitem<>@olditem or
   	   @dtactualdate<>@oldactdate or
   
   	   @dtjctranstype<>@oldjctranstype or @dtdescription<>@olddescription or
     	   @dtglco <> @oldglco or isnull(@dtgltransacct,'')<>isnull(@oldgltransacct,'') or isnull(@dtgloffsetacct,'')<>isnull(@oldgloffsetacct,'') or
   	   @dtreversalstatus<>@oldreversalstatus or
   	   @dtbilledunits<>@oldbilledunits or @dtbilledamt<>@oldbilledamt
   
   
   	   begin
   	    select @errortext = @errorstart + ' - Old information in batch does not match existing info in JC Detail.'
   	    exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	    if @rcode <> 0 goto bspexit
   	    goto nextrec
   	   end
   
   	/*validate the old values*/
   
         /* validate old Contract JC Transaction Type - AP, AR, JC, Etc...*/
         if @oldjctranstype <> 'AP' and @oldjctranstype <> 'AR' and @oldjctranstype <> 'JC'
   	 begin
   	  select @errortext = @errorstart + isnull(@oldjctranstype,'') + ' is an Invalid JCTransType for this batch.'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
   	 end
   
         /* validate old contract */
         if not exists (select * from dbo.bJCCM with (nolock) where JCCo = @co and Contract = @oldcontract)
   	 begin
             select @errortext = @errorstart + 'Old Contract ' + isnull(@oldcontract,'') + ' - is invalid.'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
             if @rcode <> 0 goto bspexit
     	  goto SkipItemVal2   /* if invalid then skip item validation*/
            end
   
         /* validate old item */
         exec @rcode = bspJCCIVal @tojcco, @oldcontract, @olditem, @msg=@errmsg output
         if @rcode = 1
            begin
             select @errortext = @errorstart + 'Old Item' + isnull(@olditem,'') + ' - ' + isnull(@errmsg,'')
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
    	  goto SkipItemVal2   /* if invalid then skip item validation*/
   
         end
   
   SkipItemVal2:
   
         /*validate Old GLAccounts */
         exec @rcode = dbo.bspGLACfPostable @oldglco, @oldgltransacct, 'J', @errmsg output
         if @rcode <> 0
    	 begin
   	  select @errortext = @errorstart + 'OLD Transaction GLAcct:' + isnull(@oldgltransacct,'') + ' ' + isnull(@errmsg,'')
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
       	 end
   
         /*only validate offset acct if not null */
         if not @oldgloffsetacct is null
   
   	begin
   	 exec @rcode = dbo.bspGLACfPostable @oldglco, @oldgloffsetacct, 'N', @errmsg output
   	 if @rcode <> 0
               begin
   	     select @errortext = @errorstart + 'OLD Offset GLAcct:' + isnull(@oldgloffsetacct,'') + ' ' + isnull(@errmsg,'')
   	     exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     if @rcode <> 0 goto bspexit
       	    end
           end
   
          /*validate Reversal Status, can only be 0 or 1, 2, 3 for changed entries */
         if @oldreversalstatus<>0 and @oldreversalstatus<>1 and
            @oldreversalstatus<>2 and @oldreversalstatus<>3
     	 begin
   	  select @errortext = @errorstart + 'old reversal status:' + isnull(convert(char(2),@oldreversalstatus),'') + ' is invalid!'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
       	 end
   
       end
   
       /*before we update the audit make sure that both accounts arnt the same */
   
       if @gltransacct=@gloffsetacct
   	 begin
   	  select @errortext = @errorstart + 'Debit account and credit account cannot be the same!'
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
    	  goto nextrec
   
       	 end
   
       if @oldgltransacct=@oldgloffsetacct and @oldgltransacct is not null and @oldgloffsetacct is not null
   	 begin
   	  select @errortext = @errorstart + 'Debit account and credit account cannot be the same !'
   
   	  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  if @rcode <> 0 goto bspexit
    	  goto nextrec
       	 end
   
       update_audit:	/* update GL Detail Audit  - only update if Amount, GLAcct or Void flag changes */
       if (@transtype<>'C') or (@oldgltransacct<>@gltransacct or @oldgloffsetacct<>@gloffsetacct or @oldbilledamt <> @billedamt)
          begin
   	if @transtype <> 'A' and @oldbilledamt <> 0	/* don't add GL distributions for 0 amounts */
   	   begin
    	   /* insert 'old' entry for posted GL Account */
   
   	      insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
   		       		ItemTrans, Contract, Item, JCTransType,
   				ActDate, Description, Amount)
    			values (@co, @mth, @batchid, @oldglco, @oldgltransacct, @seq, 0,
   
      				@itemtrans, @oldcontract, @olditem, @oldjctranstype,
   				@oldactdate, @olddescription, ( @oldbilledamt))
   			if @@rowcount = 0
   		   		begin
   		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
   		     		goto bspexit
   		   		end
   	     if not @oldgloffsetacct is null
   		begin
   	         insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
     		       		    ItemTrans, Contract, Item, JCTransType,
   				    ActDate, Description, Amount)
    			    values (@co, @mth, @batchid, @oldglco, @oldgloffsetacct, @seq, 0,
      				    @itemtrans, @oldcontract, @olditem, @oldjctranstype,
   				    @oldactdate, @olddescription, (-1*@oldbilledamt))
   			if @@rowcount = 0
   		   		begin
   		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
   		     		goto bspexit
   		   		end
                   end
              end
   
   
   	if @transtype <> 'D' and @billedamt <> 0	/* don't add GL distributions for 0 amounts */
   	  begin
    	   /* insert entry for Adjustment*/
   	      insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
   		       		ItemTrans, Contract, Item, JCTransType,
   				ActDate, Description, Amount)
    			values (@co, @mth, @batchid, @glco, @gltransacct, @seq, 1,
      				@itemtrans, @contract, @item, @jctranstype,
   
   				@actdate, @description, (-1 *@billedamt))
   			if @@rowcount = 0
   		   		begin
   		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
   		     		goto bspexit
   		   		end
   
   
   	   /* if theres a credit account, make that entry too */
   
   
   	     if not @gloffsetacct is null
   		begin
   	         insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
     		       		    ItemTrans, Contract, Item, JCTransType,
   				    ActDate, Description, Amount)
    			    values (@co, @mth, @batchid, @jcglco, @gloffsetacct, @seq, 1,
      				    @itemtrans, @contract, @item, @jctranstype,
   				    @actdate, @description, (@billedamt))
   			if @@rowcount = 0
   		   		begin
   		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
   		     		goto bspexit
   		   		end
                   end
   
   		/* Post InterCompany Accounty */
    		if @glco <> @tojcglco
       		begin
      	 		select @intercoarglacct = ARGLAcct, @intercoapglacct = APGLAcct
        		from dbo.bGLIA with (nolock)
        		where ARGLCo = @tojcglco and APGLCo = @glco
      			if @@rowcount = 0
            		begin
      				select @errmsg = 'Intercompany Accounts not setup in GL. From:' +
                	convert(varchar(3),@tojcglco) + ' To: ' + convert(varchar(3),@glco), @rcode = 1
      		     	goto bspexit
            		end
      			-- validate intercompany GL Accounts
        		exec @rcode = dbo.bspGLACfPostable @tojcglco, @intercoarglacct, 'R', @errmsg output
        		if @rcode <> 0
            		begin
      	      		select @errmsg = 'Intercompany AR Account:' + isnull(@intercoarglacct,'') + ':  ' + isnull(@errmsg,''), @rcode = 1
      	  	  		goto bspexit
          	 		end
      			exec @rcode = dbo.bspGLACfPostable @glco, @intercoapglacct, 'P', @errmsg output
        		if @rcode <> 0
       			begin
      		 		select @errmsg = 'Intercompany AP Account:' + isnull(@intercoapglacct,'') + ':  ' + isnull(@errmsg,'')
      		 		goto bspexit
      				end
   
    			--Insert Intercompany payable @intercoapglacct
       		update dbo.bJCIA
       		Set Amount = Amount + @billedamt
       		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@intercoapglacct and BatchSeq=@seq and OldNew=1
       		if @@rowcount = 0
          		begin
   	         insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
     		       		ItemTrans, Contract, Item, JCTransType,
   				    ActDate, Description, Amount)
    			    values (@co, @mth, @batchid, @glco, @intercoapglacct, @seq, 1,
      				    @itemtrans, @contract, @item, @jctranstype,
   				    @actdate, @description, (@billedamt))
   			if @@rowcount = 0
   		   		begin
   		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
   		     		goto bspexit
   		   		end
   
          		end
   
       		-- Intercompany Receivables - Debit in AP GL Co# @intercoarglacct
       		update dbo.bJCIA
       		Set Amount = Amount - @billedamt
       		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@tojcglco and GLAcct=@intercoarglacct and BatchSeq=@seq and OldNew=1
       		if @@rowcount = 0
          		begin
   	         insert into dbo.bJCIA (JCCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
     		       		ItemTrans, Contract, Item, JCTransType,
   				    ActDate, Description, Amount)
    			    values (@co, @mth, @batchid, @tojcglco, @intercoarglacct, @seq, 1,
      				    @itemtrans, @contract, @item, @jctranstype,
   				    @actdate, @description, (-1*@billedamt))
    		 	if @@rowcount = 0
   			  begin
   		  		select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
   		   		goto bspexit
   			  end
         end
    end
   
   	  end
        end
   nextrec:
   select @seq=Min(BatchSeq) from bJCIB
    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq>@seq
   
   
   end
   
   /* check GL totals - This should always be in balance  */
   select @glco = GLCo, @balamt=isnull(sum(isnull(Amount,0)),0) 
   from dbo.bJCIA with (nolock)
   where JCCo = @co and Mth = @mth and BatchId = @batchid
   group by GLCo
   having isnull(sum(Amount),0) <> 0
   if @@rowcount <> 0
       begin
       select @errortext =  'GL Company ' + isnull(convert(varchar(3), @glco),'') + ' entries do not balance!'
       exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       end
   
   
   
   /* check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3	/* valid - ok to post */
   if exists(select * from dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @status = 2	/* validation errors */
   
   	end
   update dbo.bHQBC
   	set Status = @status
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCIBVal] TO [public]
GO
