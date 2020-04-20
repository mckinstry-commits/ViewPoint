SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMTBPost    Script Date: 8/28/99 9:36:09 AM ******/
    CREATE              procedure [dbo].[bspCMTBPost]
    /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : kb 12/6/98
    *               GG 10/07/99 Fix for null GL Description Control
    *               MH 10/11/00 Add attachement code
    *               MH 12/1/00 Issue 10534.  Pulling previous posted transfer back into batch and
    *                          reversing the CMAcct numbers created unique index violations.  Prior to updated
    *                          'transfer from' trapping the CMRefSeq number.  During the update of 'transfer from'
    *                          set the CMRefSeq to 99.  After 'transfer to' completed change the 'transfer from'
    *                          CMRefSeq number back to orig value which should be zero.
    *               MV 05/30/01 - Issue 12769 - BatchUserMemoUpdate
    *               TV/RM 02/22/02 Attachment Fix
    *               CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
    *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
    *				ES 03/31/04 - 18616 - re-index attachments
    *				rm 06/03/04 - 18616 - Insert GUID into CMTT instead of CMDT
    *				DANF 03/15/05 - #27294 - Remove scrollable cursor.
	*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	*				MH 05/18/09 - Issue 133433/127603
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    * USAGE:
    *  Used by the CM Batch processing form to post a validated batch
    *  of CM Transfer entries.
    *
    *  Updates bCMTT, bCMDT, and bGLDT
    *  Deletes successfully posted bCMTB rows
   
    *  Clears bCMTA and bHQCC when complete
    * INPUT PARAMETERS
    *   CMCo         CM Co
    *   Mth          Month of batch to insert transaction into
    *   BatchID      BatchId Transaction should be put into
    *   PostingDate  Date written out as posted date if posted successfully
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid,
    * RETURN VALUE
    *   0 success
    *   1 fail
    *****************************************************/
	(@co bCompany, @mth bMonth, @batchid bBatchID,
	@dateposted bDate = null, @errmsg varchar(255) output)
    as
   
    declare @rcode int, @source bSource, @tablename char(20),
    @inuseby bVPUserName, @status tinyint, @seq int, @transtype char(1),
    @cmtransfertrans bTrans, @fromcmco bCompany, @fromcmacct bCMAcct, @fromcmtrans bTrans,
    @tocmco bCompany, @tocmacct bCMAcct, @tocmtrans bTrans, @cmref bCMRef,
    @actdate bDate, @description bTransDesc, @amount bDollar,
    @fromglco bCompany, @fromcmglacct bGLAcct, @toglco bCompany,
    @tocmglacct bGLAcct,  @jrnl bJrnl, @glinterfacelvl tinyint,
    @gldesccontrol varchar(60), @gltrans bTrans, @glref bGLRef,
    @oldnew tinyint, @batchseq int, @glco bCompany, @glacct bGLAcct,
    @findidx int, @desc bTransDesc, @found varchar(10), @desccontrol varchar(60),
    @gldetaildesc varchar(60), @glsummarydesc varchar(60),
    @opencursor tinyint, @opencursorcmta tinyint, @keyfield varchar(128), @updatekeyfield varchar(128),
    @deletekeyfield varchar(128), @tempcmrefseq tinyint, @guid uniqueIdentifier, @Notes varchar(256)
   
    set nocount on
   
    select @rcode = 0
   
    /* set open cursor flags to false */
    select @opencursor = 0, @opencursorcmta = 0
   
    /* get GL interface info from CM Company */
	select @jrnl = Jrnl, @gldetaildesc = GLDetailDesc,
	@glsummarydesc = GLSummaryDesc, @glinterfacelvl = GLInterfaceLvl
	from bCMCO where CMCo = @co
    if @@rowcount = 0
	begin
		select @errmsg = 'Missing CM Company!', @rcode=1
		goto bspexit
	end
   
    /* check for date posted */
	if @dateposted is null
	begin
		select @errmsg = 'Missing posting date!', @rcode = 1
		goto bspexit
	end
   
    /* validate HQ Batch */
    select @source = 'CM Trnsfr'
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'CMTB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
   
    if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
	begin
		select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
		goto bspexit
	end
   
    /* set HQ Batch status to 4 (posting in progress) */
   
    update bHQBC set Status = 4, DatePosted = @dateposted
   	where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
	begin
		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
		goto bspexit
	end
   
    /* declare cursor on CM Transfer Batch for posting */
   
	declare bcCMTB cursor for select BatchSeq, BatchTransType, CMTransferTrans,
	FromCMCo, FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans,
	CMRef, Amount, ActDate, Description, UniqueAttchID
	from bCMTB
	where Co = @co and Mth = @mth and BatchId = @batchid

   
    /* open cursor */
   
    open bcCMTB
   
    /* set open cursor flag to true */
    select @opencursor = 1
   
    /* loop through all rows in this batch */
    cm_posting_loop:
   
	fetch next from bcCMTB into @seq, @transtype, @cmtransfertrans,
	@fromcmco, @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans,
	@cmref, @amount, @actdate, @description, @guid

  	if (@@fetch_status <> 0) goto cm_posting_end
   
	begin transaction
   
       	select @fromglco = GLCo from bCMCO where CMCo = @fromcmco
    	if @@rowcount = 0 goto cm_posting_error
   
       	select @toglco = GLCo from bCMCO where CMCo = @tocmco
    	if @@rowcount = 0 goto cm_posting_error
   
       	select @fromcmglacct = GLAcct from bCMAC where CMCo = @fromcmco and CMAcct = @fromcmacct
    	if @@rowcount = 0 goto cm_posting_error
   
       	select @tocmglacct = GLAcct from bCMAC where CMCo = @tocmco and CMAcct = @tocmacct
    	if @@rowcount = 0 goto cm_posting_error
   
    	if @transtype = 'A'	/* add new CM Transfer and Detail transactions */
 		begin
 		/* get next available trans # for CM Detail */
   
			select @tablename = 'bCMDT'
			exec @fromcmtrans = bspHQTCNextTrans @tablename, @fromcmco, @mth, @errmsg output
			if @fromcmtrans = 0 goto cm_posting_error
   
    		/* insert 'transfer from' CM Detail entry */
			insert bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
			PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq,
			Payee, CMTransferTrans, GLCo, CMGLAcct, GLAcct, Void, ClearDate, InUseBatchId, Purge)
			values (@fromcmco, @mth, @fromcmtrans, @fromcmacct, 3, @co, 'CM Trnsfr', @actdate,
			@dateposted, @description, (@amount * -1), 0, @batchid, @cmref, 0,
			null, null, @fromglco, @fromcmglacct, null, 'N', null, null, 'N')
			if @@rowcount = 0 goto cm_posting_error
   
			/* get next available trans # for CM Detail */
			select @tablename = 'bCMDT'
			exec @tocmtrans = bspHQTCNextTrans @tablename, @tocmco, @mth, @errmsg output
			if @tocmtrans = 0 goto cm_posting_error

			/* insert 'transfer to' CM Detail entry */
			insert bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
			PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq,
			Payee, CMTransferTrans, GLCo, CMGLAcct,	GLAcct, Void, ClearDate, InUseBatchId, Purge)
			values (@tocmco, @mth, @tocmtrans, @tocmacct, 3, @co, 'CM Trnsfr', @actdate,
			@dateposted, @description, @amount, 0, @batchid, @cmref, 0,
			null, null, @toglco, @tocmglacct, null, 'N', null, null, 'N')
			if @@rowcount = 0 goto cm_posting_error
   
   
			/* now that we have the CMDT Trans#s, add the CMTT entry */

			/* get next available transaction # for CMTT */

			select @tablename = 'bCMTT'
			exec @cmtransfertrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
			if @cmtransfertrans = 0 goto cm_posting_error

			/* insert CM Transfer entry */
			insert bCMTT (CMCo, Mth, CMTransferTrans, FromCMCo, FromCMAcct, FromCMTrans,
			ToCMCo, ToCMAcct, ToCMTrans, CMRef, Amount, ActDate, DatePosted,
			Description, Batchid, InUseBatchId, Purge, UniqueAttchID )
			values (@co, @mth, @cmtransfertrans, @fromcmco, @fromcmacct, @fromcmtrans,
			@tocmco, @tocmacct, @tocmtrans, @cmref, @amount, @actdate, @dateposted,
			@description, @batchid, null, 'N', @guid)
			if @@rowcount = 0 goto cm_posting_error
   
			/* update the Transfer Trans# to the 'transfer to' CM Detail entry */
			update bCMDT set CMTransferTrans = @cmtransfertrans
			where CMCo = @tocmco and Mth = @mth and CMTrans = @tocmtrans

			/* update the Transfer Trans# to the 'transfer from' CM Detail entry */
			update bCMDT set CMTransferTrans = @cmtransfertrans
			where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans

			/* update the Transfer Trans # to the batch record for BatchUserMemoUpdate */
			update bCMTB set CMTransferTrans = @cmtransfertrans where Co = @co and Mth = @mth
			and BatchId = @batchid and BatchSeq = @seq
			if @@rowcount = 0 goto cm_posting_error

			/* update all three CM Trans to bCMTA */
			update bCMTA set CMTransferTrans = @cmtransfertrans, FromCMTrans = @fromcmtrans, ToCMTrans = @tocmtrans
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
   		end
   
   
		if @transtype = 'C'	/* update existing CM Transfer and Detail transactions */
		begin
			/* update existing CM Transfer entry - cannot change To or From CM Co#s */
			update bCMTT
			set FromCMAcct = @fromcmacct, ToCMAcct = @tocmacct, ActDate = @actdate,
			Description = @description, Batchid = @batchid, Amount = @amount,
			InUseBatchId = null, CMRef = @cmref, DatePosted = @dateposted
			where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtransfertrans

			if @@rowcount = 0 goto cm_posting_error

			/* update existing CM Detail 'transfer from' entry */
			--Issue 10534
			--Trap CMRefSeq.
			select @tempcmrefseq = CMRefSeq from CMDT where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans

			--Add 1 to @tempcmrefseq to keep this transaction unique.
			update bCMDT
			set CMAcct = @fromcmacct, ActDate = @actdate, PostedDate = @dateposted,
			Description = @description, BatchId = @batchid, Amount = (@amount * -1),
			InUseBatchId = null, CMRef = @cmref, GLCo = @fromglco, CMGLAcct = @fromcmglacct,
			CMRefSeq = (@tempcmrefseq + 1), UniqueAttchID = @guid
			where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans


			/* update existing CM Detail 'transfer to' entry */
			update bCMDT
			set CMAcct = @tocmacct, ActDate = @actdate, PostedDate = @dateposted,
			Description = @description, BatchId = @batchid, Amount = @amount,
			InUseBatchId = null, CMRef = @cmref, GLCo = @toglco, CMGLAcct = @tocmglacct
			where CMCo = @tocmco and Mth = @mth and CMTrans = @tocmtrans

			--change CMRefSeq back to orig
			update CMDT set CMRefSeq = @tempcmrefseq where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans
			--end Issue 10534 mh 12/1/00
   
       end
   
   
   
      	if @transtype = 'D'	/* delete existing GL transaction */
		begin
			delete bCMDT where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans
			delete bCMDT where CMCo = @tocmco and Mth = @mth and CMTrans = @tocmtrans
			delete bCMTT where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtransfertrans
		end

		--call bspBatchUserMemoUpdate to update user memos in bCMTB before deleting the batch record
		if @transtype in ('A', 'C')
		begin
			exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'CM Trans', @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = 'Unable to update User Memo in CMTT.', @rcode = 1
				goto cm_posting_error
			end
		end
      
       	/* delete current row from cursor */
       	delete from bCMTB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    commit transaction
   
--   	-- issue 18616 Refresh indexes for this header if attachments exist
--   	if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
   
	goto cm_posting_loop

	cm_posting_error:	/* error occured within transaction - rollback any updates and continue */
	rollback transaction
	goto cm_posting_loop

	cm_posting_end:		/* no more rows to process */
	/* make sure batch is empty */
	if exists(select * from bCMTB where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
		select @errmsg = 'Not all batch entries were posted - unable to close batch!', @rcode = 1
		goto bspexit
	end
   
	/* Update GL using CM Transfer Audit - bCMTA */
    if @glinterfacelvl = 0	 /* no update, just clear audit file */
	begin
		delete bCMTA where Co = @co and Mth = @mth and BatchId = @batchid
		goto gl_update_end
	end

	/* set GL Reference using Batch Id - right justified 10 chars */
	select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)

   
    if @glinterfacelvl = 1 /* summary - one entry per GL Co/GL Account, unless GL Acct flagged for detail */
    begin
   
		/* create 'summary' cursor on CM Transfer Audit */
	--#142278
  DECLARE bcCMTA CURSOR local fast_forward FOR 
	  SELECT    c.GLCo,
				c.GLAcct,
				ISNULL(CONVERT (numeric(12, 2), SUM(c.Amount)), 0)
	  FROM      dbo.bCMTA c
				JOIN bGLAC g ON c.GLCo = g.GLCo
								AND c.GLAcct = g.GLAcct 
	  WHERE     c.Co = @co
				AND c.Mth = @mth
				AND c.BatchId = @batchid
				AND g.InterfaceDetail = 'N'
	  GROUP BY  c.GLCo,
				c.GLAcct
   
    	/* open cursor */
        open bcCMTA
    	select @opencursorcmta = 1
   
    	gl_summary_posting_loop:
    	fetch next from bcCMTA into @glco, @glacct, @amount
   

		if (@@fetch_status <> 0) goto gl_summary_posting_end

		begin transaction

			/* get next available transaction # for GLDT */
			select @tablename = 'bGLDT'

			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto gl_summary_posting_error

			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
			ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
			Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @dateposted,
			@dateposted, @glsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
    		if @@rowcount = 0 goto gl_summary_posting_error
   
			delete bCMTA where Co = @co and Mth = @mth and BatchId = @batchid
			and GLCo = @glco and GLAcct = @glacct
			if @@rowcount = 0 goto gl_summary_posting_error
   
        commit transaction
   
   
    	goto gl_summary_posting_loop
   
		gl_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
		rollback transaction
		goto gl_summary_posting_loop
   
    	gl_summary_posting_end:	/* no more rows to process */
   
		close bcCMTA
		deallocate bcCMTA
		select @opencursorcmta = 0
    end
   
   
    /* detail update to GL for everything remaining in bCMTA */
	declare bcCMTA cursor local fast_forward for select GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans,
	FromCMCo, FromCMAcct, ToCMCo, ToCMAcct, CMRef, Amount, ActDate, Description
	from bCMTA where Co = @co and Mth = @mth and BatchId = @batchid 

    /* open cursor */
   
    open bcCMTA
    select @opencursorcmta = 1
   
    gl_detail_posting_loop:
	fetch next from bcCMTA into @glco, @glacct, @batchseq, @oldnew, @cmtransfertrans,
	@fromcmco, @fromcmacct, @tocmco, @tocmacct, @cmref, @amount, @actdate, @description
   
   
	if (@@fetch_status <> 0) goto gl_detail_posting_end
   
    begin transaction

		/* parse out the description */
		select @desccontrol = isnull(rtrim(@gldetaildesc),'')

		select @desc=''
      
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

			if @found = 'Trans No'
			select @desc = @desc + '/' + convert(varchar(8), @cmtransfertrans)
			if @found = 'CM Ref'
			select @desc = @desc + '/' + @cmref
			if @found = 'Trans Type'
			select @desc = @desc + '/' + convert(varchar(2), 3)
			if @found = 'Trans Desc'
			select @desc = @desc + '/' + @description
			if @found = 'CM Acct'
			select @desc = @desc + '/From:' +convert(varchar(3), @fromcmco)
			+ ':' + convert(varchar(4), @fromcmacct) + '/To:' +

			convert(varchar(3), @tocmco) + ':' + convert(varchar(4), @tocmacct)
		end
   
		/* get next available transaction # for GLDT */
		select @tablename = 'bGLDT'
		exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
		if @gltrans = 0 goto gl_detail_posting_error

		insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
		ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
		Adjust, InUseBatchId, Purge)
		values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @actdate,
		@dateposted, @desc, @batchid, @amount, 0,'N', null, 'N')
		if @@rowcount = 0 goto gl_detail_posting_error

		delete from bCMTA where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and
		GLAcct = @glacct and BatchSeq = @batchseq and OldNew = @oldnew

    commit transaction
   
   
	goto gl_detail_posting_loop

    gl_detail_posting_error:	/* error occured within transaction - rollback any updates and continue */
	rollback transaction
	goto gl_detail_posting_loop

	gl_detail_posting_end:	/* no more rows to process */
	close bcCMTA
	deallocate bcCMTA

	select @opencursorcmta = 0

    gl_update_end:
	/* make sure CM Transfer Audit is empty */
	if exists(select * from bCMTA where Co = @co and Mth = @mth and BatchId = @batchid)
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
		close bcCMTB
		deallocate bcCMTB
	end

	if @opencursorcmta = 1
	begin
		close bcCMTA
		deallocate bcCMTA
	end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMTBPost] TO [public]
GO
