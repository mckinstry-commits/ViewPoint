SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspCMDBPost]
/***********************************************************
* CREATED BY: SE   8/20/96
* MODIFIED By : GG 01/26/99
*               GG 10/07/99 Fix for null GL Description Control
*               MV 05/30/01 - Issue 12769 - update user memos in bspBatchUserMemoUpdate
*               TV 03/06/02 Attachment Fix
*               CMW 04/05/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*				ES 03/31/04 - 18616 - re-index attachments
*				DANF 03/15/05 - #27294 - Remove scrollable cursor.
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				mh 05/18/09 - Issue 133433/127603
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
*				CHS	04/22/2011	- B-03437 add TaxCode
*
* USAGE:
* Posts a validated batch of CMDB entries
* deletes successfully posted bCMDB rows

* clears bCMDA and bHQCC when complete
*
* INPUT PARAMETERS
*   CMCo        CM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   PostingDate Posting date to write out if successful
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
   
	(@co bCompany, @mth bMonth, @batchid bBatchID,
	@dateposted bDate = null, @errmsg varchar(60) output)
	as


	set nocount on

	declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20),
	@inuseby bVPUserName, @status tinyint, @seq int, @transtype char(1),
	@cmtrans bTrans, @cmacct bCMAcct, @cmtranstype bCMTransType,
	@actdate bDate, @description bDesc, @amount bDollar, @cmref bCMRef, @cmrefseq tinyint,
	@payee varchar(20), @glco bCompany, @cmglacct bGLAcct, @glacct bGLAcct, @void bYN,
	@jrnl bJrnl, @glinterfacelvl tinyint, @gldesccontrol varchar(60), @gltrans bTrans, @glref bGLRef,
	@oldnew tinyint, @batchseq int, @findidx int, @desc varchar(60), @found varchar(10),
	@desccontrol varchar(60), @opencursorcmda tinyint, @gldetaildesc varchar(60), @glsummarydesc varchar(60),
	@keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128), @guid UniqueIdentifier,
	@TaxGroup bGroup, @TaxCode bTaxCode, @Notes varchar(256)
   
   
	select @rcode = 0

	/* set open cursor flags to false */
	select @opencursor = 0, @opencursorcmda = 0

	/* get GL interface info from CMCO */
	select @jrnl = Jrnl, @gldetaildesc = GLDetailDesc, @glsummarydesc = GLSummaryDesc, 
	@glinterfacelvl = GLInterfaceLvl
	from bCMCO where CMCo = @co
	if @@rowcount = 0
	begin
		select @errmsg = 'Missing CM Company!', @rcode = 1
		goto bspexit
	end
   
	/* check for date posted */
	if @dateposted is null
	begin
		select @errmsg = 'Missing posting date!', @rcode = 1
		goto bspexit
	end
   
   
	/* validate HQ Batch */
	select @source = 'CM Entry'
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'CMDB', @errmsg output, @status output
	if @rcode <> 0 goto bspexit

	if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
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
   
	/* declare cursor on CM Detail Batch for posting */
	declare bcCMDB cursor for select BatchSeq, BatchTransType, CMTrans, CMAcct, CMTransType,
	ActDate, Description, Amount, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, GLAcct, Void, UniqueAttchID,
	TaxGroup, TaxCode
	from bCMDB
	where Co = @co and Mth = @mth and BatchId = @batchid for update
   
	/* open cursor */
	open bcCMDB

	/* set open cursor flag to true */
	select @opencursor = 1

	/* loop through all rows in this batch */
	cm_posting_loop:
	fetch next from bcCMDB into @seq, @transtype, @cmtrans, @cmacct, @cmtranstype,
	@actdate, @description, @amount, @cmref, @cmrefseq, @payee, @glco,
	@cmglacct, @glacct, @void, @guid, @TaxGroup, @TaxCode

	if (@@fetch_status <> 0) goto cm_posting_end
   
   	begin transaction
   
	if @transtype = 'A'	/* add new CM Detail Transaction */
	begin
		/* get next available transaction # for CMDT */
		select @tablename = 'bCMDT'
		exec @cmtrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
		if @cmtrans = 0 goto cm_posting_error
   
		/* insert CM Detail */--CHS	04/22/2011	- B-03437 add TaxCode
		insert bCMDT (CMCo, Mth, CMTrans, CMAcct, StmtDate, CMTransType, SourceCo, Source, ActDate,
		PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee, GLCo,
		CMGLAcct, GLAcct, Void, ClearDate, InUseBatchId, Purge, UniqueAttchID,
		TaxGroup, TaxCode)
		values (@co, @mth, @cmtrans, @cmacct, null, @cmtranstype, @co, 'CM Entry', @actdate,
		@dateposted, @description, @amount, 0, @batchid, @cmref,@cmrefseq, @payee, @glco,
		@cmglacct, @glacct, @void, null, null, 'N', @guid, @TaxGroup, @TaxCode)
		if @@rowcount = 0 goto cm_posting_error
   
		/* now that we have a CM Trans, update it to bCMDA and bCMDB (for BatchUserMemoUpdate) */
		update bCMDA set CMTrans = @cmtrans where CMCo = @co and Mth = @mth and BatchId = @batchid
		and BatchSeq = @seq
		update bCMDB set CMTrans = @cmtrans where Co = @co and Mth = @mth and BatchId = @batchid
		and BatchSeq = @seq
                    
   	end
   
   	if @transtype = 'C'	/* update existing CM Detail Transaction */
   	begin
   
		update bCMDT
		set CMAcct = @cmacct, ActDate = @actdate, PostedDate = @dateposted, Description = @description,
		BatchId = @batchid, Amount = @amount, InUseBatchId = null,
		CMRef = @cmref, CMRefSeq = @cmrefseq, Payee = @payee, GLCo = @glco, CMGLAcct = @cmglacct,
		GLAcct = @glacct, Void = @void, UniqueAttchID = @guid, TaxGroup = @TaxGroup, TaxCode = @TaxCode
		where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
                 
	end
   
	if @transtype = 'D'	/* delete existing CM Detail Transaction */
	begin
		delete bCMDT where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
		if @@rowcount = 0 goto cm_posting_error
	end

	--call bspBatchUserMemoUpdate to update user memos in bCMDB before deleting the batch record
	if @transtype in ('A','C')
	begin
		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'CM Post', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = 'Unable to update User Memo in CMDB.', @rcode = 1
			goto cm_posting_error
		end
	end
   
   	/* delete current row from cursor */
   	delete from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
   	/* commit transaction */
   	commit transaction
   
--   	-- issue 18616 Refresh indexes for this header if attachments exist
--   	if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
   
   	goto cm_posting_loop
   
   
	cm_posting_error:		/* error occured within transaction - rollback any updates and continue */
	rollback transaction
	goto cm_posting_loop
   
   
	cm_posting_end:			/* no more rows to process */

	/* make sure batch is empty */
	if exists(select * from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
		select @errmsg = 'Not all CM Detail batch entries were posted - unable to close batch!', @rcode = 1
		goto bspexit
	end
   
   
	gl_update:	/* update GL using entries from bCMDA */
   	if @glinterfacelvl = 0	 /* no update */
	begin
		delete bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
		goto gl_update_end
  	end
   
   	/* set GL Reference using Batch Id - right justified 10 chars */
   	select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
   
	if @glinterfacelvl = 1	 /* summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail */
	begin

		/* declare 'summary' cursor on CM Detail Audit */
--#142278
  DECLARE bcCMDA CURSOR local fast_forward FOR 
	  SELECT    c.GLCo,
				c.GLAcct,
				ISNULL(CONVERT (numeric(12, 2), SUM(c.Amount)), 0)
	  FROM      dbo.bCMDA c
				JOIN dbo.bGLAC g ON c.GLCo = g.GLCo
									AND c.GLAcct = g.GLAcct
	  WHERE     c.CMCo = @co
				AND c.Mth = @mth
				AND c.BatchId = @batchid
				AND g.InterfaceDetail = 'N'
	  GROUP BY  c.GLCo,
				c.GLAcct

		/* open cursor */
		open bcCMDA
		select @opencursorcmda = 1
   
   		gl_summary_posting_loop:
   	    fetch next from bcCMDA into @glco, @glacct, @amount
     
		if @@fetch_status <> 0 goto gl_summary_posting_end

		begin transaction

			/* get next available transaction # for GLDT */
			select @tablename = 'bGLDT'
			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto gl_summary_posting_error

			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
			ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
			Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref,  @co, 'CM Entry', @dateposted,
			@dateposted, @glsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
			if @@rowcount = 0 goto gl_summary_posting_error

			delete bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
			and GLCo = @glco and GLAcct = @glacct

			commit transaction

			goto gl_summary_posting_loop
   
   
   			gl_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
   			rollback transaction
   			goto gl_summary_posting_loop
   
   			gl_summary_posting_end:	/* no more rows to process */
			close bcCMDA
			deallocate bcCMDA
			select @opencursorcmda = 0
   	  	end
   
		/* detail update to GL for everything remaining in bCMDA */
		declare bcCMDA cursor local fast_forward for select GLCo, GLAcct, BatchSeq, OldNew, CMTrans, CMAcct,

		CMTransType, ActDate, Description, Amount, CMRef, Payee
		from bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
   
		/* open cursor */
		open bcCMDA
		select @opencursorcmda = 1
   
   		gl_detail_posting_loop:
   
		fetch next from bcCMDA into @glco, @glacct, @batchseq, @oldnew, @cmtrans, @cmacct,
		@cmtranstype, @actdate, @description, @amount, @cmref, @payee
   
     	if @@fetch_status <> 0 goto gl_detail_posting_end
   
      	begin transaction
   
   	       	/* parse out the description */
   	       	select @desccontrol = isnull(rtrim(@gldetaildesc),'')
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

            	if @found = 'CM Trans'
               		select @desc = @desc + '/' + convert(varchar(8), @cmtrans)

            	if @found = 'CM Ref'

               		select @desc = @desc + '/' + @cmref
            	if @found = 'Trans Type'
               		select @desc = @desc + '/' + convert(varchar(2), @cmtranstype)
            	if @found = 'Trans Desc'
               		select @desc = @desc + '/' + @description
            	if @found = 'CM Acct'
               		select @desc = @desc + '/' + convert(varchar(4), @cmacct)
			end
   
			-- remove leading '/'
			if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))

			/* get next available transaction # for GLDT */
			select @tablename = 'bGLDT'
			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto gl_detail_posting_error
   
			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
			ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
			Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @jrnl,  @glref, @co, 'CM Entry', @actdate,
			@dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
   			if @@rowcount = 0 goto gl_detail_posting_error
   
			delete from bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
			and GLCo = @glco and GLAcct = @glacct and BatchSeq = @batchseq and
			OldNew = @oldnew
   
   		commit transaction
   
   		goto gl_detail_posting_loop
   
   		gl_detail_posting_error:	/* error occured within transaction - rollback any updates and continue */
   		rollback transaction
   		goto gl_detail_posting_loop
   
   		gl_detail_posting_end:	/* no more rows to process */
		close bcCMDA
		deallocate bcCMDA
		select @opencursorcmda = 0

		gl_update_end:
		/* make sure GL Audit is empty */
		if exists(select * from bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid)
		begin
			select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
			goto bspexit
		end
   
		-- set interface levels note string
		select @Notes=Notes from bHQBC
		where Co = @co and Mth = @mth and BatchId = @batchid
		if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
		select @Notes=@Notes +
		'GL Interface Level set at: ' + convert(char(1), a.GLInterfaceLvl) + char(13) + char(10)
		from bCMCO a where CMCo=@co
      
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
	if @opencursor = 1
	begin
		close bcCMDB
		deallocate bcCMDB
	end

	if @opencursorcmda = 1
	begin
		close bcCMDA
		deallocate bcCMDA
	end

GO
GRANT EXECUTE ON  [dbo].[bspCMDBPost] TO [public]
GO
