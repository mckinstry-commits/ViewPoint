SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLDBVal    Script Date: 10/1/2003 11:50:42 AM ******/
   CREATE        procedure [dbo].[bspGLDBVal]
   /************************************************************************
   * Created: ???
   * Last Revised: 04/02/99 GG
   *			GG 04/16/01 - exclude Memo accounts from balance check #12939
   *			SR 08/08/02 - Add 'GL JrnlXCo' as valid source and added @interco to the cursor fetch
   *			GG 12/03/02 - #19372 - correct validation and cleanup
   *			GF 02/11/03 - #19599 - added validation for reversal journal when inter-co. Not allowed.
   *			GG 03/17/03 - #20406 - fix interco GL distributions
   *			DC 5/15/03 - #21287 - update statement needs to include proper where clause
   *			DC 10/1/03 - #22537 - Duplicate Key Row in GLDA when validating intercompany journal entries
   *			DANF 10/17/03 - #22537 - Removed intercompany account validation and added intercompany to GLDA index.
   *			DC 11/26/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
   *			GP 08/05/09 - 134681 Add validation for interco AR and AP accounts
   *
   *
   * Usage: Called from GL Batch Process form to validate entries
   *	in bGLDB for a select batch - must be called prior to posting the batch.
   *	After initial Batch and GL checks, bHQBC Status set to 1 (validation in progress)
   * 	bHQBE (Batch Errors), and bGLDA (GL Detail Audit) entries are deleted.
   *	Creates a cursor on bGLDB to validate each entry individually.
   * 	Errors in batch added to bHQBE using bspHQBEInsert
   *	Account distributions added to bGLDA
   *	Jrnl and GL Reference debit and credit totals must balance, unless
   *	GL company allows unbalanced entries.
   *	bHQBC Status updated to 2 if errors found, or 3 if OK to post
   *
   *Input Params: Co, Month, and BatchId
   *
   *Output Params: Error message if failure
   *
   *Return Code: 0 if successfull (even if entries added to bHQBE)
   *	       1  if failed
   *************************************************************************/
   
     	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
    
   as
   
   set nocount on
   
   declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
   	@adj bYN, @opencursor tinyint, @lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint,
   	@unbal bYN, @fy bMonth, @seq int, @transtype char(1), @gltrans bTrans, @glacct bGLAcct,
   	@jrnl bJrnl, @glref bGLRef, @dbsource bSource, @actdate bDate, @description bTransDesc, @amt bDollar,
   	@oldglacct bGLAcct, @oldactdate bDate, @olddesc bTransDesc, @oldamt bDollar, @errorhdr varchar(30),
   	@errortext varchar(255), @accttype char(1), @active bYN, @glrefadj bYN, @dtglacct bGLAcct, @dtjrnl bJrnl,
   	@dtglref bGLRef, @dtsource bSource, @dtactdate bDate, @dtdesc bTransDesc, @dtamt bDollar, @errno int, 
   	@interco bCompany, @dasource bSource, @apglco bCompany, @arglco bCompany, @arglacct bGLAcct,
   	@apglacct bGLAcct
    
   select @rcode = 0, @opencursor = 0
   
   /* validate HQ Batch */
   select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   	@status = Status, @adj = Adjust
   	from dbo.bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
   	goto bspexit
   	end
   if @source <> 'GL Jrnl'
   	begin
   	select @errmsg = 'Invalid Batch source - must be ''GL Jrnl''!', @rcode = 1
   	goto bspexit
   	end
   if @tablename <> 'GLDB'
   	begin
   	select @errmsg = 'Invalid Batch table name - must be ''bGLDB''!', @rcode = 1
   	goto bspexit
   	end
   if @inuseby is null
   	begin
   	select @errmsg = 'HQ Batch Control must first be updated as ''In Use''!', @rcode = 1
   	goto bspexit
   	end
   if @inuseby <> SUSER_SNAME()
   	begin
   	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'MISSING: @inuseby'), @rcode = 1
   	goto bspexit
   	end
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
    
   /* validate GL Company and Month */
   select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen,
   	@unbal = Unbal
   from bGLCO where GLCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid GL Company #', @rcode = 1
   	goto bspexit
   	end
   if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   	begin
   	select @errmsg = 'Not an open month', @rcode = 1
   	goto bspexit
   	end
   
   /* validate Fiscal Year */
   select @fy = FYEMO
   from bGLFY
   where GLCo = @co and @mth >= BeginMth and @mth <= FYEMO
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Must first add Fiscal Year', @rcode = 1
   	goto bspexit
   	end
   if @adj = 'Y' and @mth <> @fy
   	begin
   	select @errmsg = 'Adjustment entries must be made in a Fiscal Year ending month', @rcode = 1
   	goto bspexit
   	end
    
   
   /* set HQ Batch status to 1 (validation in progress) */
   update bHQBC
   set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
     	end
   
   --DC # 21287
   -- set InterCo to current GL Co# if null
   update bGLDB set InterCo = Co where Co = @co and Mth = @mth and BatchId = @batchid and InterCo is null
    
   /* clear HQ Batch Errors */
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   /* clear GL Detail Audit */
   delete bGLDA where Co = @co and Mth = @mth and BatchId = @batchid
   /*clear HQCC entries */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- refresh HQ Close Control with an entry for each GL Co# in the Batch
   insert bHQCC(Co, Mth, BatchId, GLCo)
   select distinct Co, Mth, BatchId, InterCo
   from bGLDB
   where Co=@co and Mth=@mth and BatchId = @batchid
    
   /* declare cursor on GL Detail Batch for validation */
   declare bcGLDB cursor for
   select BatchSeq, BatchTransType, GLTrans, GLAcct, Jrnl, GLRef,
   	Source, ActDate, Description, Amount, OldGLAcct, OldActDate, OldDesc, OldAmount, InterCo
   from bGLDB
   where Co = @co and Mth = @mth and BatchId = @batchid
    
   /* open cursor and set cursor flag */
   open bcGLDB 
   select @opencursor = 1
    
   GLDB_loop:	-- validate each batch entry
   	fetch next from bcGLDB into @seq, @transtype, @gltrans, @glacct, @jrnl,
   		@glref, @dbsource, @actdate, @description, @amt, @oldglacct, @oldactdate,
   		@olddesc, @oldamt, @interco
   
   	if @@fetch_status <> 0 goto GLDB_end
    
     	/* validate GL Detail Batch info for each entry */
     	select @errorhdr = 'Seq#' + convert(varchar(6),@seq)
   
   	-- default Source - will be changed to 'GL JrnlXCo' if determined to be intercompany entry
   	select @dasource = 'GL Jrnl'
   
     	/* validate transaction type */
     	if @transtype not in ('A','C','D')
     		begin
     		select @errortext = @errorhdr + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   		goto GLDB_loop
     		end
    
     	/* validation for Add types */
     	if @transtype = 'A'
     		begin
     		/* check GL Trans# */
     		if @gltrans is not null
     			begin
     			select @errortext = @errorhdr + ' - ''New'' entries may not reference a GL Transaction #.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end	
     		/* check Source */
     		if @dbsource <> 'GL Jrnl' 
     			begin
     			select @errortext = @errorhdr + ' - ''New'' entries must have a ''GL Jrnl'' source.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end	
   
   		/* validate GL Account in 'posted to' GL Co# */
     		select @accttype = AcctType, @active = Active
     		from bGLAC
   		where GLCo = @interco and GLAcct = @glacct
     		if @@rowcount = 0
     			begin
     			select @errortext = @errorhdr + ' - Missing GL Account: ' + @glacct
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			goto GLDB_loop
     			end
     		if @accttype = 'H'
     			begin
     			select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is a Heading Account.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		if @active = 'N'
     			begin
     			select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is inactive.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
   		-- validate Journal in current GL Co#
     		exec @errno = bspGLJrnlVal @co, @jrnl, @errmsg output
     		if @errno <> 0
     			begin
     			select @errortext = @errorhdr + ' - ' + @errmsg
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end	
     		/* make sure we have a GL Reference */ 
     		if @glref is null or @glref = ''
     			begin
     			select @errortext = @errorhdr + ' - Must provide a GL Reference.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		/* if GL Reference exists validate adjustment flag */
     		select @glrefadj = Adjust
   		from bGLRF
     		where GLCo = @co and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
     		if @@rowcount <> 0 and @glrefadj <> @adj
     			begin
     			select @errortext = @errorhdr + ' - Batch and GL Reference Adjustment flags must match.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		/* all old values should be null */
     		if @oldglacct is not null or @oldactdate is not null or @olddesc is not null or @oldamt is not null
     			begin
     			select @errortext = @errorhdr + ' - Old info in batch must be ''null'' for ''Add'' entries.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end 
   		
   		-- intercompany validation
   		if @interco <> @co
   			begin 	
      			/* validate GL Company and Month */
     			select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
     			from bGLCO
   			where GLCo = @interco
     			if @@rowcount = 0
     				begin  		
   				select @errortext = @errorhdr + ' - Invalid GL Co#:' + convert(varchar(5), isnull(@interco,'MISSING'))
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
     				begin
     				select @errortext = @errorhdr + ' - Not an open month in GL Co#:' + convert(varchar(5), isnull(@interco,'MISSING'))
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end 
     			/* validate Fiscal Year */
     			select @fy = FYEMO
   			from bGLFY where GLCo = @interco and @mth >= BeginMth and @mth <= FYEMO
     			if @@rowcount = 0
     				begin
     				select @errortext = @errorhdr + ' - Must first add fiscal year in GL Co#:' + convert(varchar(5), isnull(@interco,'MISSING'))
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end	
   			/*Validate Journal*/
   			-- issue #19599 - REVERSAL Journal's not allowed
   			exec @errno = bspGLJrnlValForGLJE @co, @jrnl, @interco, @errmsg output
     			if @errno <> 0
     				begin
     				select @errortext = @errorhdr + ' - ' + @errmsg
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end	
   			/* if GL Reference exists validate adjustment flag for intercompany*/
     			select @glrefadj = Adjust
   			from bGLRF
     			where GLCo = @interco and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
     			if @@rowcount <> 0 and @glrefadj <> @adj
     				begin
     				select @errortext = @errorhdr + ' - Batch and GL Reference Adjustment flags must match.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
   			-- validate Interco GL Accounts
   			select @arglco = case when @amt < 0 then @interco else @co end
   			select @apglco = case when @amt < 0 then @co else @interco end
   			select @arglacct = ARGLAcct, @apglacct = APGLAcct
   			from bGLIA
   			where ARGLCo = @arglco and APGLCo = @apglco
   			if @@rowcount = 0
   				begin		
   				select @errortext = @errorhdr + ' - Intercompany accounts not setup for AR GL Co#:' + convert(varchar(10),@arglco)
   					+ ' and AP GL Co#:' + convert(varchar(10),@apglco)
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
   				end
   			if @glacct = @arglacct --134681
   				begin
				    select @errortext = @errorhdr + ' - Interco: ' + convert(varchar(10),@arglco) + ' AR Account: ' + @arglacct + ' matches Posted GL Account: ' + @glacct
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop   	
				end
			if @glacct = @apglacct --134681
   				begin
				    select @errortext = @errorhdr + ' - Interco: ' + convert(varchar(10),@apglco) + ' AP Account: ' + @apglacct + ' matches Posted GL Account: ' + @glacct
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop   	
				end				
   			/* validate intercompany AR GL Account */ 	
     			select @accttype = AcctType, @active = Active
     			from bGLAC where GLCo = @arglco and GLAcct = @arglacct
     			if @@rowcount = 0
     				begin
     				select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' not setup in GL Co#:' + convert(varchar(5), @arglco)
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end	
     			if @accttype = 'H'
     				begin
     				select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' is a Heading Account.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			if @active = 'N'
     				begin
     				select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' is inactive.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
   			/* validate intercompany AP GL Account */ 	
     			select @accttype = AcctType, @active = Active
     			from bGLAC where GLCo = @apglco and GLAcct = @apglacct
     			if @@rowcount = 0
     				begin
     				select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' not setup in GL Co#:' + convert(varchar(5), @arglco)
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			if @accttype = 'H'
     				begin
     				select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' is a Heading Account.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			if @active = 'N'
     				begin
     				select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' is inactive.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
   			end
   		end			-- end of validation for 'Add's
   
   
   	/* validation for Change and Delete types */
     	if @transtype in ('C','D')
     		begin
     		/* get existing values from GLDT */
     		select @dtglacct = GLAcct, @dtjrnl = Jrnl, @dtglref = GLRef, @dtsource = Source, 
     			@dtactdate = ActDate, @dtdesc = Description, @dtamt = Amount
     		from bGLDT 
   		where GLCo = @co and Mth = @mth and GLTrans = @gltrans
     		if @@rowcount = 0
     			begin 
     			select @errortext = @errorhdr + ' - Missing GL Transaction#: ' + convert(varchar(10),isnull(@gltrans,'MISSING gltrans'))
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		/* make sure old values in batch match existing values in detail */
     		if @oldglacct <> @dtglacct or @oldactdate <> @dtactdate
   			or isnull(@olddesc,'') <> isnull(@dtdesc,'') or @oldamt <> @dtamt
     			begin
     			select @errortext = @errorhdr + ' - Old info in batch does not match existing info in GL Detail.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
   		-- check for intercompany entries - only allowed with 'Add's'
   		if @interco <> @co
   			begin
   			select @errortext = @errorhdr + ' Intercompany postings only allowed with ''Add'' entries.'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		/* validate GL Account if different than existing */
     		if @glacct <> @dtglacct
     			begin
     			select @accttype = AcctType, @active = Active
     			from bGLAC where GLCo = @co and GLAcct = @glacct
     			if @@rowcount = 0
     				begin
     				select @errortext = @errorhdr + ' - Invalid GL Account: ' + @glacct
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
     				goto GLDB_loop
     				end
     			if @accttype = 'H'
     				begin
     				select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is a Heading Account.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			if @active = 'N'
     				begin
     				select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is inactive.'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
   				goto GLDB_loop
     				end
     			end
    		/* validate Journal, Reference, and Source - cannot be changed */
     		if @jrnl <> @dtjrnl or @glref <> @dtglref
     			begin
     			select @errortext = @errorhdr + ' - Journal and/or GL Reference in batch doesn''t match existing detail.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		if @dbsource <> @dtsource
     			begin
     			select @errortext = @errorhdr + ' - Source in batch doesn''t match existing detail.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
   			goto GLDB_loop
     			end
     		end
   
    
     	/* update GL Detail Audit */
     	if @transtype <> 'A'
     		begin
     		/* insert 'old' entry */
     		insert bGLDA (Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew,
     			GLTrans, Source, ActDate, Description, Amount, InterCo)
     		values (@co, @mth, @batchid, @jrnl, @glref, @oldglacct, @seq, 0, @gltrans,
     			@dbsource, @oldactdate, @olddesc, (-1 * @oldamt), @interco)	/* reverse sign on old amount */
     		end
   
     	if @transtype <> 'D' /* insert 'new' entry */
     		begin 
   		-- all entries involved in an intercompany journal entry should have 'GL JrnlXCo' source
   		select @dasource = @dbsource	-- source for 'normal' entries
   		if @interco <> @co or ((@interco = @co) and @transtype = 'A' and
   			exists(select 1 from bGLDB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq
   					and BatchTransType = 'A' and Jrnl = @jrnl and GLRef = @glref and InterCo <> @co))
   			select @dasource = 'GL JrnlXCo'
   
   		-- add 'new' entry for posted GL Account
   		insert bGLDA (Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew, GLTrans,
   			Source, ActDate, Description, Amount, InterCo)
     		values (@co, @mth, @batchid, @jrnl, @glref, @glacct, @seq, 1, @gltrans,
     			@dasource, @actdate, @description, @amt, @interco)
   
   		-- add intercompany entries as needed
   		if @interco <> @co 	
   			begin
   			-- debit intercompany AR GL Account
   			insert bGLDA (Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew, GLTrans,
   				Source, ActDate, Description, Amount, InterCo)
     			values (@co, @mth, @batchid, @jrnl, @glref, @arglacct, @seq, 1, @gltrans,
     				'GL JrnlXCo', @actdate, @description, abs(@amt), @arglco)	-- #20406 use abs value
   			-- credit intercompany AP GL Account
   			insert bGLDA (Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew, GLTrans,
   				Source, ActDate, Description, Amount, InterCo)
     			values (@co, @mth, @batchid, @jrnl, @glref, @apglacct, @seq, 1, @gltrans,
     				'GL JrnlXCo', @actdate, @description, (-1 * abs(@amt)), @apglco)	-- #20406 use abs value
   			end
     		end
   
   	goto GLDB_loop	-- get next batch entry
   
   GLDB_end:	-- finished with batch entry validation
   	close bcGLDB
   	deallocate bcGLDB	
   	select @opencursor = 0	
   	 
   /* check Journal/GL Reference totals - unless unbalanced entries allowed  */
   if @unbal <> 'Y'
   	begin
     	select @jrnl = d.Jrnl, @glref = d.GLRef, @interco=d.InterCo
       from bGLDA d
    	join bGLAC a on d.InterCo = a.GLCo and d.GLAcct = a.GLAcct 
     	where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and a.AcctType <> 'M' -- exclude memo accounts 
     	group by d.InterCo, d.Jrnl, d.GLRef
     	having sum(Amount) <> 0
     	if @@rowcount <> 0
     		begin
   		select @errortext = 'GL Co#: ' + convert(varchar(6),isnull(@interco,'MISSING')) + ' Journal: ' + @jrnl + ' and GL Reference: ' + @glref + ' entries don''t balance'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
     		end
     	end
    
   /* check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3	/* valid - ok to post */
   if exists(select 1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	select @status = 2	/* validation errors */
   
   update bHQBC
   set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
     	end
    
   bspexit:
   	if @opencursor = 1
     		begin
     		close bcGLDB
     		deallocate bcGLDB
     		end
    
   	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[bspGLDBVal]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLDBVal] TO [public]
GO
