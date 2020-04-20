SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** Object:  Stored Procedure dbo.bspJCIBPost    Script Date: 8/28/99 9:36:21 AM ******/
CREATE procedure [dbo].[bspJCIBPost]
/***********************************************************
*CREATED BY :	
*				JM    04/18/1997
*MODIFIED BY:	
*				GG    01/26/1999
*				GG    10/07/1999 - Fix for null GL Description Control
*				DANF  10/19/2000 - Add attachments
*				DANF  03/22/2001 - Add update of ARCo, ARInvoice, and ARCheck
*				MV    06/21/2001 - Issue 12769 BatchUserMemoUpdate
*				TV/RM 02/22/2002 - Attachment Fix
*				CMW   04/04/2002 - Added bHQBC.Notes interface levels update (issue # 16692).
*				GG    04/08/2002 - #16702 - remove parameter from bspBatchUserMemoUpdate
*				DANF  04/11/2002 - Intercompany Postings
*				DANF  02/25/2004 - 23854 Update Actual date when pulled back into a batch and changed.
*				TV               - 23061 added isnulls
*				GWC	  04/13/2004 - 18616 Moved re-index of attachment code to below the commit transaction
*				GF 02/07/2008 - issue #127017 gl revenue level 1 - summary not consolidating GL accounts.
*								also found that item trans not being updated into JCIA and that detail GL
*								description missing item.
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				JonathanP 05/29/2009 - Issue 133437 - Removed code that was updating the TableName in HQAT
*
*
*				 
* USAGE:
* Posts a validated batch of JCIB entries deletes successfully
* posted bJCIB rows clears bJCIA and bHQCC when complete.
*
* INPUT PARAMETERS
*   JCCo        	JC Co
*   Month       	Month of batch
*   BatchId     	Batch ID to validate
*   PostingDate 	Posting date to write out if successful
*
* OUTPUT PARAMETERS
*   @errmsg     	if something went wrong
*
* RETURN VALUE
*   0   		success
*   1   		fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID,
@dateposted bDate = null, @errmsg varchar(60) output)
as
set nocount on

declare @actdate bDate,	@amount bDollar,@batchseq int,@BilledAmt bDollar, @billedunits bUnits,
		@contract bContract, @desc varchar(60), @desccontrol varchar(60), @description bTransDesc,
		@errorstart varchar(50), @findidx int, @found varchar(30), @glacct bGLAcct, @glco bCompany,
		@gloffsetacct bGLAcct, @glref bGLRef, @glrevdetaildesc varchar(60), @glrevjournal bJrnl,
		@glrevlevel tinyint, @glrevoverride bYN, @glrevsummarydesc varchar(30), @gltrans bTrans,
		@gltransacct bGLAcct, @InUseBatchId bBatchID, @inuseby bVPUserName, @item bContractItem,
		@itemtrans bTrans, @jctranstype varchar(2), @lastseq int,@oldnew tinyint, @origitemtrans bTrans,
		@origmth bMonth, @rcode int, @reversalstatus tinyint,@seq int, @stmtdate bDate, @status tinyint,
		@subtype char(1), @tablename char(20),@transsource bSource, @transtype char(1),
		@keyfield varchar(128), @updatekeyfield varchar(128),
		@arco bCompany, @arinvoice varchar(10), @archeck varchar(10),
		@guid uniqueIdentifier, @Notes varchar(256), @tojcco bCompany
   
    select @rcode = 0, @lastseq=0
    /* get GL interface info from JCCO */
    select @glrevjournal = GLRevJournal, @glrevdetaildesc = GLRevDetailDesc,
    	@glrevsummarydesc = GLRevSummaryDesc, @glrevlevel = GLRevLevel
    	from bJCCO where JCCo = @co
----
----select @errmsg = 'GL Revenue Level: ' + convert(varchar(1), @glrevlevel), @rcode = 1
----goto bspexit

    if @@rowcount = 0
    	begin
        	select @errmsg = 'Missing JC Company!', @rcode = 1
        	goto bspexit
       	end
   
    /* check for date posted */
    if @dateposted is null
    	begin
    	select @errmsg = 'Missing posting date!', @rcode = 1
    	goto bspexit
    	end
   
    /* validate HQ Batch */
    select @transsource = 'JC RevAdj'
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @transsource, 'JCIB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4 /* valid - OK to post, or posting in progress */
    	begin
    	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
    	goto bspexit
    	end
   
    /* set HQ Batch status to 4 (posting in progress) */
    update bHQBC
    	set Status = 4, DatePosted = @dateposted
    	where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
   
    /* loop through all rows in this batch */
    select @seq=-1  /*set to -1 to begin the search */
    jc_posting_loop:
    	select @seq=Min(BatchSeq)
    	  from bJCIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq>@seq
    	if @seq is null goto jc_posting_end
    	select @transtype=TransType, @itemtrans=ItemTrans, @contract=Contract,
    	 @item=Item, @actdate=ActDate, @jctranstype=JCTransType, @description=Description,
    	 @glco=GLCo, @gltransacct=GLTransAcct, @gloffsetacct=GLOffsetAcct, @reversalstatus=ReversalStatus,
    	 @origmth=OrigMth, @origitemtrans=OrigItemTrans, @billedunits=BilledUnits, @BilledAmt=BilledAmt,
        @arco =ARCo, @arinvoice = ARInvoice, @archeck = ARCheck, @guid = UniqueAttchID, @tojcco = ToJCCo
    	from bJCIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
    	if (@seq=@lastseq)
    	   begin
      	         select @errmsg = 'Duplicate Seq, error with cursor!', @rcode=1
    	  	 goto bspexit
     	   end
   
       if @jctranstype <> 'IC' select @tojcco = @co
   
    	begin transaction
    	if @transtype = 'A'	/* add new JC Detail Transaction */
    		begin
    		/* get next available transaction # for JCID */
    		select @tablename = 'bJCID'
    		exec @itemtrans = bspHQTCNextTrans @tablename, @tojcco, @mth, @errmsg output
    		if @itemtrans = 0 goto jc_posting_error
   
   		
   			--Moved this code below commit transaction to address rejection for #18616
   			-- issue 18616 Refresh indexes for this header if attachments exist
   		 	--if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
     
   
    	/* insert JC Detail */
    		insert bJCID (JCCo, Mth, ItemTrans, Contract, Item, PostedDate, ActualDate, JCTransType,
    			TransSource, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
    			ReversalStatus, BilledUnits, BilledAmt, ARCo, ARInvoice, ARCheck, UniqueAttchID, SrcJCCo)
       		values (@tojcco, @mth, @itemtrans, @contract, @item, @dateposted, @actdate, @jctranstype,
       			'JC RevAdj', @description, @batchid, @glco, @gltransacct, @gloffsetacct,
    			@reversalstatus, @billedunits, @BilledAmt, @arco, @arinvoice, @archeck, @guid, @tojcco)
    		if @@rowcount = 0 goto jc_posting_error
    	/* If new transaction is a reversing entry then flag the original entry as reversed */
    	        if @reversalstatus = 2
    		   update bJCID set ReversalStatus = 3
    			where JCCo=@tojcco and Mth=@origmth and ItemTrans=@origitemtrans
    	/* If new transaction is canceling reversing entry then flag the original entry as not reversing */
    	        if @reversalstatus = 4
    		   update bJCID set ReversalStatus = 0
    			where JCCo=@tojcco and Mth=@origmth and ItemTrans=@origitemtrans
    		end
   
			/* update ItemTrans in batch table bJCIB for BatchUserMemoUpdate */
			update bJCIB set ItemTrans = @itemtrans
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
			---- update bJCIA with ItemTrans
			update bJCIA set ItemTrans = @itemtrans
			where JCCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq

    	if @transtype = 'C'	/* update existing JC Revenue Detail Transaction */
    		begin
   
   		--Moved this code below commit transaction to address rejection for #18616
   		 -- issue 18616 Refresh indexes for this header if attachments exist
   		 -- if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
     
   
    		update bJCID
    		set Contract = @contract, Item = @item, PostedDate = @dateposted, 
   			ActualDate = @actdate, JCTransType=@jctranstype,
    			@transsource='JC RevAdj', Description = @description,
    			BatchId=@batchid, GLCo=@glco, GLTransAcct=@gltransacct,
    			GLOffsetAcct=@gloffsetacct,
    			 ReversalStatus=@reversalstatus,
    			BilledUnits=@billedunits, BilledAmt=@BilledAmt, InUseBatchId=null,
                            ARCo = @arco, ARInvoice = @arinvoice, ARCheck = @archeck
    			where JCCo = @tojcco and Mth = @mth and ItemTrans = @itemtrans
    		if @@rowcount = 0 goto jc_posting_error
    		end
    	if @transtype = 'D'	/* delete existing JC Detail Transaction */
    		begin
    		delete bJCID where JCCo = @tojcco and Mth = @mth and ItemTrans = @itemtrans
    		if @@rowcount = 0 goto jc_posting_error
    		end
   
       /* call bspBatchUserMemoUpdate to update user memos in bJCID before deleting the batch record */
       if @transtype <> 'D'
       begin
       exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'JC AdjRev', @errmsg output
       if @rcode <> 0
           begin
           select @errmsg = 'Unable to update User Memo in JCID.', @rcode = 1
   		goto jc_posting_error
           end
       end
   
    	/* delete current row from cursor */
    	delete from bJCIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
    	/* commit transaction */
   
    	commit transaction
   
   	-- Issue 18616 Refresh indexes for this header if attachments exist
   	if @transtype in ('A', 'C')
   	begin
   		if @guid is not null 
   		begin
   			exec bspHQRefreshIndexes null, null, @guid, null
     		end
   	end
   
   
    	goto jc_posting_loop
    jc_posting_error:		/* error occured within transaction - rollback any updates and continue */
    	rollback transaction
    	goto jc_posting_loop
    jc_posting_end:			/* no more rows to process */
    	/* make sure batch is empty */
    	if exists(select * from bJCIB where Co = @co and Mth = @mth and BatchId = @batchid)
    		begin
    		select @errmsg = 'Not all JC Revenue batch entries were posted - unable to close batch!', @rcode = 1
    		goto bspexit
    		end


---- update GL using entries from bJCIA
gl_update:
---- no update
if @glrevlevel = 0
	begin
	delete bJCIA where JCCo = @co and Mth = @mth and BatchId = @batchid
	end

---- set GL Reference using Batch Id - right justified 10 chars
select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)

---- summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail
if @glrevlevel = 1
	begin
	---- spin through each GLCo
	select @glco=min(GLCo) from bJCIA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid
	while @glco is not null
		begin
		---- spin through each acct
		select @glacct=min(c.GLAcct)
		from bJCIA c with (nolock) join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail = 'N'
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and g.InterfaceDetail='N'
		while @glacct is not null
			begin

			---- get GL amount
			select @BilledAmt=convert(numeric(12,2),sum(c.Amount))
			from bJCIA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and c.GLAcct=@glacct

			begin transaction

			---- get next available transaction # for GLDT
			select @tablename = 'bGLDT'
			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto gl_summary_posting_error

			---- insert GLDT
			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
					ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
					Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @glrevjournal, @glref, @co, 'JC RevAdj', @dateposted,
					@dateposted, @glrevsummarydesc, @batchid, @BilledAmt, 0,'N', null, 'N')
			if @@rowcount = 0 goto gl_summary_posting_error

			---- delete GL audit
			delete bJCIA where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@glacct

			commit transaction

			goto gl_nextGLAcct

			---- error occured within transaction - rollback any updates and continue
			gl_summary_posting_error:
				rollback transaction

			gl_nextGLAcct:
			---- get next acct
			select @glacct=min(c.GLAcct)
			from bJCIA c with (nolock) join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail='N'
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and g.InterfaceDetail = 'N' and c.GLAcct>@glacct
			end
		---- get next GLCo
 		select @glco=min(GLCo) from bJCIA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo>@glco
		end
	end


    	/* detail update to GL for everything remaining in bJCIA */
                    /* spin through each GLCo */
     		select @glco=min(GLCo) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    		while @glco is not null
    		begin
    		/* spin through each acct */
    		select @glacct=min(GLAcct) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco
    		while @glacct is not null
    		begin
    		/* spin through each batch seq */
    		select @batchseq=min(BatchSeq) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco and GLAcct=@glacct
    		while @batchseq is not null
    		begin
    		/* spin through each oldnew */
    		select @oldnew=min(OldNew) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq
    		while @oldnew is not null
    		begin
    		/* read record */
    		select  @glco=GLCo, @glacct=GLAcct, @batchseq=BatchSeq, @oldnew=OldNew, @itemtrans=ItemTrans,
    		     @contract=Contract, @item=Item, @jctranstype=JCTransType, @actdate=ActDate,
    		     @description=Description, @BilledAmt=Amount
    		from bJCIA where JCCo = @co and Mth = @mth and BatchId = @batchid
    			and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq and @oldnew=OldNew
    	      	begin transaction
    	       	/* parse out the description */
    	       	select @desccontrol = isnull(rtrim(@glrevdetaildesc),'')
    	       	select @desc = ''
                   	while (@desccontrol <> '')
                    	begin
                     	select @findidx = charindex('/',@desccontrol)
                     	if @findidx = 0
    		    		begin
                         		select @found = @desccontrol
    		     		select @desccontrol = ''
    		    		end
                     	else
    		    		begin
        		     		select @found=substring(@desccontrol,1,@findidx-1)
    		     		select @desccontrol = substring(@desccontrol,@findidx+1,60)
                        		end
                     	if @found = 'Trans #'
                        		select @desc = @desc + '/' + isnull(convert(varchar(8), @itemtrans),'')
                     	if @found = 'Contract'
                        		select @desc = @desc + '/' + isnull(@contract,'')
                     	if @found = 'Item'
                        		select @desc = @desc + '/' + isnull(@item,'')
                    	if @found = 'Trans Type'
                        		select @desc = @desc + '/' +  isnull(@jctranstype,'')
                     	if @found = 'Desc'
                        		select @desc = @desc + '/' + isnull(@description,'')

                   		end
   
                 -- remove leading '/'
                if substring(@desc,1,1)='/' select @desc = isnull(substring(@desc,2,datalength(@desc)),'')
   
     	       	/* get next available transaction # for GLDT */
    	       	select @tablename = 'bGLDT'
    	       	exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
    	       	if @gltrans = 0 goto gl_detail_posting_error
    	       	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    			ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
    			Adjust, InUseBatchId, Purge)
    		values(@glco, @mth, @gltrans, @glacct, @glrevjournal, @glref,
    			@co, 'JC RevAdj', @actdate, @dateposted, @desc, @batchid, @BilledAmt, 0,'N', null, 'N')
    		if @@rowcount = 0 goto gl_detail_posting_error
    		/* delete from batch if posted */
      	       	delete from bJCIA  where JCCo = @co and Mth = @mth and BatchId = @batchid
    			and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq and @oldnew=OldNew
    		commit transaction
   
   
   
    		goto gl_detail_next
    	gl_detail_posting_error:	/* error occured within transaction - rollback any updates and continue */
    		rollback transaction
    	gl_detail_next:
    		/* spin through each oldnew */
    		select @oldnew=min(OldNew) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq and OldNew>@oldnew
    		end
    		select @batchseq=min(BatchSeq) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco and GLAcct=@glacct and BatchSeq>@batchseq
    		end
    		select @glacct=min(GLAcct) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo=@glco and GLAcct>@glacct
    		end
    		select @glco=min(GLCo) from bJCIA
    			where JCCo = @co and Mth = @mth and BatchId = @batchid
    			  and GLCo>@glco
    		end
    gl_update_end:
    	/* make sure GL Audit is empty */
    	if exists(select * from bJCIA where JCCo = @co and Mth = @mth and BatchId = @batchid)
    		begin
    		select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
    		goto bspexit
    		end
   
       -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
           'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
           'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
           'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
       from bJCCO a where JCCo=@co
   
    /* delete HQ Close Control entries */
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    /* set HQ Batch status to 5 (posted) */
    update bHQBC
    	set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    		goto bspexit
    		end
    bspexit:
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCIBPost] TO [public]
GO
