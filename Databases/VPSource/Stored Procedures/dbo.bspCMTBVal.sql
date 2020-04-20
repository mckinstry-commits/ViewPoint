SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMTBVal    Script Date: 8/28/99 9:36:09 AM ******/
   CREATE  proc [dbo].[bspCMTBVal]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : GG 02/28/97
    *		JM 6/16/98 - set @fromglacct and @toglacct to
    *			space(10) when null so they will be inserted
    *			in CMTA
    *              LM 3/30/99 changed sum(isnull... isnull(sum...
    *      GG 01/17/01 - fixed CMRef validation, general cleanup
    *
    * USAGE:
    * Validates each entry in bCMTB for a selected batch - must be called
    * prior to posting the batch.
    *
    * After initial Batch and CM checks, bHQBC Status set to 1 (validation in progress)
    * bHQBE (Batch Errors), and bCMTA (CM Transfer Audit) entries are deleted.
    *
    * Creates a cursor on bCMTB to validate each entry individually.
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * Account distributions added to bCMTA
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    * INPUT PARAMETERS
    *   CMCo         CM Co
    *   Mth          Month of batch to insert transaction into
    *   BatchID      BatchId Transaction should be put into
    * INPUT PARAMETERS
    *   @msg     Error message if invalid,
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(100) output)
   as
   
   declare @rcode int, @errortext varchar(255),@opencursor tinyint, @lastsubmth bMonth,
       @maxopen tinyint, @active bYN, @seq int, @cmtransfertrans bTrans, @fromcmco bCompany,
       @fromcmacct bCMAcct, @fromcmtrans bTrans, @tocmco bCompany, @tocmacct bCMAcct,
       @tocmtrans bTrans, @cmref bCMRef, @amt bDollar, @actdate bDate, @desc bDesc,
       @oldfromcmacct bCMAcct, @oldtocmacct bCMAcct, @oldactdate bDate, @oldamt bDollar,
       @oldcmref bCMRef, @olddesc bDesc, @toglco bCompany, @fromglco bCompany, @fromglacct bGLAcct,
       @toglacct bGLAcct, @fromcmglacct bGLAcct, @tocmglacct bGLAcct, @dtfromcmco bCompany,
       @dtfromcmacct bCMAcct, @dtfromcmtrans bTrans, @dttocmco bCompany, @dttocmacct bCMAcct,
       @dttocmtrans bTrans, @dtcmref bCMRef, @dtactdate bDate, @dtdesc bDesc, @dtamt bDollar,
       @dtfromglco bCompany, @dtfromcmglacct bGLAcct, @dtfromglacct bGLAcct, @dttoglco bCompany,
       @dttocmglacct bGLAcct, @dttoglacct bGLAcct, @jrnl bJrnl, @cmglco bCompany, @errorstart varchar(50),
       @subtype char(1), @transtype char(1), @status tinyint, @glco bCompany
   
   set nocount on
   
   select @rcode = 0
   
   /* set open cursor flag to false */
   select @opencursor = 0
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'CM Trnsfr', 'CMTB', @errmsg output, @status output
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
   
   /* get GL info from CM Company */
   select @cmglco = GLCo, @jrnl = Jrnl
   	from bCMCO where CMCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid CM Company #', @rcode = 1
   	goto bspexit
   	end
   
   /* validate GL Company and Month */
   select @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
   	from bGLCO where GLCo = @cmglco
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid GL Company #', @rcode = 1
   	goto bspexit
   	end
   if @mth <= @lastsubmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   	begin
   	select @errmsg = 'Not an open month', @rcode = 1
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
   
   /* clear HQ Batch Errors */
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* clear GL Transfer Audit */
   delete bCMTA where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* declare cursor on CM Transaction Batch for validation */
   declare bcCMTB cursor for select BatchSeq, BatchTransType, CMTransferTrans,
          	 FromCMCo, FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, CMRef, Amount,
            ActDate, Description, OldFromCMAcct, OldToCMAcct, OldActDate, OldAmount, OldCMRef, OldDesc
   from bCMTB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* open cursor */
   open bcCMTB
   
   /* set open cursor flag to true */
   select @opencursor = 1
   
   CMTB_loop:
       fetch next from bcCMTB into @seq, @transtype, @cmtransfertrans, @fromcmco, @fromcmacct,
   	   @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @cmref, @amt, @actdate, @desc,
   	   @oldfromcmacct, @oldtocmacct, @oldactdate, @oldamt, @oldcmref, @olddesc
   
        if @@fetch_status <> 0 goto CMTB_end
   
     	/* validate CM Transfer Batch info for each entry */
      	select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
      	/*get correct GL Co#s for update*/
      	select @fromglco = GLCo from bCMCO where CMCo = @fromcmco
      	select @toglco = GLCo from bCMCO where CMCo = @tocmco
   
   	/* make sure GL Journal is valid in both 'From' and 'To' GL Co#s */
       if not exists (select * from bGLJR where GLCo = @fromglco and @jrnl = Jrnl)
          	begin
           select @errortext = @errorstart + ' Journal ' + @jrnl + ' not setup in GL Co# ' + convert(varchar(3), @fromglco)
           goto CMTB_error
          	end
   
       if not exists (select * from bGLJR where GLCo=@toglco and @jrnl=Jrnl)
          	begin
           select @errortext = @errorstart + ' Journal ' + @jrnl + ' not setup in GL Co# ' + convert(varchar(3), @toglco)
           goto CMTB_error
          	end
   
   	/* Intercompany Journal entries needed if 'From' and 'To' GL Co#s are different */
   	if @fromglco <> @toglco
           begin
   		/* get Intercompany GL Accounts */
          	select @fromglacct = ARGLAcct, @toglacct = APGLAcct
   		from bGLIA
           where ARGLCo = @fromglco and APGLCo = @toglco
          	if @@rowcount = 0
             	begin
              	select @errortext = @errorstart + ' - Intercompany GL Account entry missing for GL Co#s: ' +
                   convert(varchar(3),@fromglco) + ' and ' + convert(varchar(3),@toglco)
              	goto CMTB_error
            	end
   
           if @fromglacct is null select @fromglacct = space(10)
           if @toglacct is null select @toglacct = space(10)
   
   
   		/* validate Intercompany AR GL Account in 'From' GL Co#  - Subleder Type must be null */
   		exec @rcode = bspGLACfPostable @fromglco, @fromglacct, 'N', @errmsg output
           if @rcode <> 0
               begin
   	       	select @errortext = @errorstart + @errmsg
   	      	goto CMTB_error
   	      	end
   
   		/*validate Intercompany AP GL Account in 'To' GL Co#  - Subledger Type must be null */
   		exec @rcode = bspGLACfPostable @toglco, @toglacct, 'N', @errmsg output
             	if @rcode <> 0
    	      	begin
     	       	select @errortext = @errorstart + @errmsg
   	       	goto CMTB_error
     	     	end
   	 	end
   
   	/* get GL Accounts for 'From' and 'To' CM Accounts */
      	select @fromcmglacct = GLAcct from bCMAC where CMCo = @fromcmco and CMAcct = @fromcmacct
      	select @tocmglacct = GLAcct from bCMAC where CMCo = @tocmco and CMAcct = @tocmacct
   
      	/* validate transaction type */
      	if @transtype <> 'A' and @transtype <> 'C' and @transtype <> 'D'
         	begin
          	select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
          	goto CMTB_error
         	end
   
      	/* make sure from and to accounts are NOT the same*/
      	if @fromcmco = @tocmco and @fromcmacct = @tocmacct
         	begin
          	select @errortext = @errorstart + ' - You cannot transfer money to the same account.'
          	goto CMTB_error
         	end
   
       /* validation for Add types */
       if @transtype = 'A'
          	begin
          	/* check Transfer Trans# */
          	if @cmtransfertrans is not null
   	  	    begin
   	   	    select @errortext = @errorstart + ' - (New) entries may not reference a CM Transaction #.'
   	   		goto CMTB_error
   	  		end
   
          	/* validate 'From' CM Account */
          	if not exists (select * from bCMAC where CMCo = @fromcmco and CMAcct = @fromcmacct)
   	  		begin
   	   		select @errortext = @errorstart + ' ' + convert(varchar(4), @fromcmacct) + ' - Invalid CM Account'
   	   		goto CMTB_error
   	  		end
   
          	/* validate 'To' CM Account */
          	if not exists (select * from bCMAC where CMCo=@tocmco and CMAcct=@tocmacct)
   	  		begin
   	   		select @errortext = @errorstart + ' ' + convert(varchar(4), @tocmacct) + ' - Invalid CM Account'
   	   		goto CMTB_error
   	  		end
   
           /* validate CM Reference */
           exec @rcode = bspCMTransferRefVal @co, @mth, @batchid, @seq,null, @cmref, @fromcmco, @fromcmacct, @tocmco, @tocmacct, @errmsg output
           if @rcode <> 0
               begin
   	       	select @errortext = @errorstart + @errmsg
   	      	goto CMTB_error
   	      	end
   
   		/*validate 'From' GL Account - must be Subleder Type 'C' or null */
           exec @rcode = bspGLACfPostable @fromglco, @fromcmglacct, 'C', @errmsg output
          	if @rcode <> 0
               begin
               select @errortext = @errorstart + @errmsg
   	   		goto CMTB_error
         	   	end
   
         	/*validate 'To' GL Account - must be Subledger Type 'C' or null */
         	exec @rcode = bspGLACfPostable @toglco, @tocmglacct, 'C', @errmsg output
          	if @rcode <> 0
    	  		begin
   	   		select @errortext = @errorstart + @errmsg
   	   		goto CMTB_error
         	   	end
   
           /* all old values should be null */
         	if @oldfromcmacct is not null or @oldtocmacct is not null or @oldactdate is not null or
             		@olddesc is not null or @oldamt is not null or @oldcmref is not null
   	  		begin
   	   		select @errortext = @errorstart + ' - Old info in batch must be null for Add entries.'
   	   		goto CMTB_error
   	 		end
   
          	end  /*end validate Adds */
   
       /* validation for Change and Delete types */
       if @transtype = 'C' or @transtype = 'D'
          	begin
   		/* get existing values from CMTT */
   	 	select @dtfromcmco=FromCMCo, @dtfromcmacct=FromCMAcct, @dtfromcmtrans=FromCMTrans,
   	       		@dttocmco=ToCMCo, @dttocmacct=ToCMAcct, @dttocmtrans=ToCMTrans,
                   		@dtcmref=CMRef, @dtactdate=ActDate, @dtdesc=Description, @dtamt=Amount
   		from bCMTT
   		where CMCo = @co and Mth = @mth and CMTransferTrans = @cmtransfertrans
           if @@rowcount = 0
   	    	begin
    	     	select @errortext = @errorstart + ' - Missing CM Transfer Transaction#'
   	     	goto CMTB_error
   	    	end
   
   		/* make sure old values in batch match existing values in detail */
           if @dtfromcmacct<>@oldfromcmacct or @dttocmacct<>@oldtocmacct or
               @dtactdate<>@oldactdate or isnull(@dtdesc,'')<>isnull(@olddesc,'')
               or @dtamt<>@oldamt or @dtcmref<>@oldcmref
    	    	begin
   	     	select @errortext = @errorstart + ' - Old info in batch does not match existing info in CM Transfer Detail.'
   	     	goto CMTB_error
       	    end
   
           /* make sure' From' and 'To' CM Co#s didnt change */
           if @fromcmco<>@dtfromcmco or @tocmco<>@dttocmco
              	begin
               select @errortext = @errorstart + ' - cannot change From or To CM Co#s.'
   	   		goto CMTB_error
       	   	end
   
           /* make sure 'From' and 'To' CM detail Trans#s didnt change */
          	if @fromcmtrans<>@dtfromcmtrans or @tocmtrans<>@dttocmtrans
              	begin
               select @errortext = @errorstart + ' - cannot change CM Transaction#s.'
   	   		goto CMTB_error
       	   	end
   
          	/* make sure 'From' CM Detail Trans exists - get old CM GL Account */
          	select @dtfromglco = GLCo, @dtfromcmglacct = CMGLAcct, @dtfromglacct = GLAcct
   		from bCMDT
   		where CMCo = @fromcmco and Mth = @mth and CMTrans = @fromcmtrans
   		if @@rowcount = 0
   			begin
          		select @errortext = @errorstart + ' - Missing old (From) CM Transaction #:.' + convert(varchar(6),@fromcmtrans)
   	   		goto CMTB_error
       	   	end
   
          	/* make sure 'To' CM Detail Trans exists - get old CM GL Account */
          	select @dttoglco = GLCo, @dttocmglacct = CMGLAcct, @dttoglacct = GLAcct
   		from bCMDT
   		where CMCo = @tocmco and Mth = @mth and CMTrans = @tocmtrans
   		if @@rowcount = 0
   			begin
               select @errortext = @errorstart + ' - Missing old (To) CM Transaction #:.' + convert(varchar(6),@tocmtrans)
   	   		goto CMTB_error
       	   	end
   
           /* make sure 'From' and 'To' GL Co#s didnt change */
           if @dtfromglco<>@fromglco and @dttoglco<>@toglco
              	begin
               select @errortext = @errorstart + ' - Cannot change From or To GL Co#s.'
   	   		goto CMTB_error
       	   	end
   
           /* validate 'From' CM Account if different*/
           if @fromcmacct<>@oldfromcmacct
              	begin
    	    	if not exists (select * from bCMAC where CMCo=@fromcmco and CMAcct=@fromcmacct)
   	       		begin
   	        	select @errortext = @errorstart + ' ' + convert(varchar(4), @fromcmacct)  + ' - Invalid (From) CM Account'
   				goto CMTB_error
   	       		end
   	   		end
   
           /* validate 'To' CM Account if different*/
           if @tocmacct <> @oldtocmacct
              	begin
    	    	if not exists (select * from bCMAC where CMCo=@tocmco and CMAcct=@tocmacct)
   	       		begin
   	        	select @errortext = @errorstart + ' ' + convert(varchar(4), @tocmacct)  + ' - Invalid (To) CM Account'
   				goto CMTB_error
   	       		end
             	end
   
   		/* validate 'From' CM GL Account if different than existing - must be Subledger Type 'C' or null */
   		if @fromcmglacct <> @dtfromcmglacct
              	begin
               exec @rcode = bspGLACfPostable @fromglco, @fromcmglacct, 'C', @errmsg output
               if @rcode <> 0
    	      		begin
   	        	select @errortext = @errorstart + @errmsg
   	        	goto CMTB_error
         	        end
   			end
   
           /* validate CM Reference */
           if @transtype = 'C' and (@oldfromcmacct <> @fromcmacct or @oldtocmacct <> @tocmacct or @oldcmref <> @cmref)
               begin
               exec @rcode = bspCMTransferRefVal @co, @mth, @batchid, @seq,@cmtransfertrans, @cmref,
                   @fromcmco, @fromcmacct, @tocmco, @tocmacct,  @errmsg output
               if @rcode <> 0
                   begin
   	            select @errortext = @errorstart + @errmsg
   	           	goto CMTB_error
   	          	end
   	       	end
   
   		/* validate 'To' CM GL Account - if changed - must be Subledger 'C' or null */
           if @tocmglacct <> @dttocmglacct
               begin
               exec @rcode = bspGLACfPostable @toglco, @tocmglacct, 'C', @errmsg output
               if @rcode <> 0
    	          	begin
   	           	select @errortext = @errorstart + @errmsg
   	           	goto CMTB_error
   				end
   			end
   		end
   
       update_audit:	/* update GL Transaction Audit  - skip update Type 'C' and no Amount or GL Account changes */
           /* if @transtype = 'C' and @oldamt = @amt and @dtfromcmglacct = @fromcmglacct and @dttocmglacct = @tocmglacct goto update_end */
   
       if @transtype <> 'A'
           begin
           /* insert 'old' entry for 'From' CM GL Account - debit */
   	    insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
               FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
    	    values (@co, @mth, @batchid, @dtfromglco, @dtfromcmglacct, @seq, 0, @cmtransfertrans, @fromcmco,
               @oldfromcmacct, @fromcmtrans, @tocmco, @oldtocmacct, @tocmtrans, @oldactdate, @oldcmref,
               @oldamt, @olddesc)
   
    	    /* insert 'old' entry for 'To' CM GL Account - credit */
          	update bCMTA		/* update needed in case same GL Account assigned to 'From' and 'To' CM Accounts  */
           set Amount=Amount + (@oldamt* -1)
   		where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @dttoglco and
                  	GLAcct = @dttocmglacct and BatchSeq = @seq and OldNew = 0
           if @@rowcount=0
               insert into bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                   FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
      	    	values (@co, @mth, @batchid, @dttoglco, @dttocmglacct, @seq, 0, @cmtransfertrans, @fromcmco,
                   @oldfromcmacct, @fromcmtrans, @tocmco, @oldtocmacct, @tocmtrans, @oldactdate, @oldcmref,
                   (-1*@oldamt), @olddesc)
   
           /* insert 'old' entries for Intercompany GL Accounts */
           if @dtfromglco <> @dttoglco
               begin
   		    /* Intercompany AR in 'From' GL Co# - credit */
   		    update bCMTA		/* update needed in case same GL Account assigned to InterCo and 'From' or 'To' CM Accounts  */
   		    set Amount=Amount + (@oldamt* -1)
   			where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @dtfromglco and
                  	GLAcct = @dtfromglacct and BatchSeq = @seq and OldNew = 0
   		    if @@rowcount=0
   		        insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                       FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
      	         	values (@co, @mth, @batchid, @dtfromglco, @fromglacct, @seq, 0, @cmtransfertrans, @fromcmco,
                       @oldfromcmacct, @fromcmtrans, @tocmco, @oldtocmacct, @tocmtrans, @oldactdate, @oldcmref,
                       (-1*@oldamt), @olddesc)
   
   		    /* Intercompany AP in 'To' GL Co# - debit */
               update bCMTA
   		    set Amount=Amount+(@oldamt)
               where Co=@co and Mth=@mth and BatchId=@batchid and GLCo=@dttoglco and
                   GLAcct=@dttoglacct and BatchSeq=@seq and OldNew=0
              	if @@rowcount = 0
      	       		insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans,
                       FromCMCo, FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef,
                       Amount, Description)
    	       		values (@co, @mth, @batchid, @dttoglco, @toglacct, @seq, 0, @cmtransfertrans, @fromcmco,
                       @oldfromcmacct, @fromcmtrans, @tocmco, @oldtocmacct, @tocmtrans, @oldactdate, @oldcmref,
                       (@oldamt), @olddesc)
   	        end
           end
   
       if @transtype <> 'D'
           begin
   	    /* insert 'new' entry for 'From' CM GL Account - credit */
           update bCMTA
           set Amount=Amount+(@amt * -1)
           where Co=@co and Mth=@mth and BatchId=@batchid and GLCo=@fromglco and
               GLAcct=@fromcmglacct and BatchSeq=@seq and OldNew=1
           if @@rowcount = 0
               insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                   FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
    	    	values (@co, @mth, @batchid, @fromglco, @fromcmglacct, @seq, 1, @cmtransfertrans, @fromcmco,
                   @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @actdate, @cmref, (-1*@amt), @desc)
   
           /* insert 'new' entry for 'To' CM GL Account - debit */
          	update bCMTA
           set Amount=Amount+(@amt)
           where Co=@co and Mth=@mth and BatchId=@batchid and GLCo=@toglco and
               GLAcct=@tocmglacct and BatchSeq=@seq and OldNew=1
           if @@rowcount = 0
   	    	insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                   FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
    	     	values (@co, @mth, @batchid, @toglco, @tocmglacct, @seq, 1, @cmtransfertrans, @fromcmco,
                   @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @actdate, @cmref, (@amt), @desc)
   
           /* insert 'new' entries for Intercompany GL Accounts */
           if @fromglco <> @toglco
   		    begin
   		    /* Intercompany AR in 'From' GL Co# - debit */
               update bCMTA
   		    set Amount=Amount+(@amt)
               where Co=@co and Mth=@mth and BatchId=@batchid and GLCo=@fromglco and
                   GLAcct=@fromglacct and BatchSeq=@seq and OldNew=1
   	      	if @@rowcount = 0
     	       		insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                       FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
     	       		values (@co, @mth, @batchid, @fromglco, @fromglacct, @seq, 1, @cmtransfertrans, @fromcmco,
                       @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @actdate, @cmref, (@amt), @desc)
   
               /* Intercompany AP in 'To' GL Co# - credit */
   		    update bCMTA
               set Amount=Amount+(@amt*-1)
               where Co=@co and Mth=@mth and BatchId=@batchid and GLCo=@toglco and
                   GLAcct=@toglacct and BatchSeq=@seq and OldNew=1
               if @@rowcount=0
                   insert bCMTA (Co, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, CMTransferTrans, FromCMCo,
                       FromCMAcct, FromCMTrans, ToCMCo, ToCMAcct, ToCMTrans, ActDate, CMRef, Amount, Description)
           	    values (@co, @mth, @batchid, @toglco, @toglacct, @seq, 1, @cmtransfertrans, @fromcmco,
                       @fromcmacct, @fromcmtrans, @tocmco, @tocmacct, @tocmtrans, @actdate, @cmref, (-1*@amt), @desc)
             	end
           end
   
   goto CMTB_loop  -- get next batch entry
   
   CMTB_error: -- error found during validation
       exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
       goto CMTB_loop  -- skip to next enry
   
   CMTB_end:   -- finished with batch entries
      	close bcCMTB
   	deallocate bcCMTB
       select @opencursor = 0
   
   
   /* check GL totals - They should always be in balance for each company  */
   select @glco = GLCo
   	from bCMTA
   	where GLCo = @co and Mth = @mth and BatchId = @batchid
    	group by GLCo
    	having isnull(sum(Amount),0) <> 0
   if @@rowcount <> 0
       	begin
        	select @errortext =  'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
       	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	goto bspexit
       	end
   
   /*clear and refresh HQCC entries */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   insert into bHQCC(Co, Mth, BatchId, GLCo)
   	select distinct Co, Mth, BatchId, GLCo
   	from bCMTA
          	where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3		/* valid - ok to post */
   	if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   		begin
   		select @status = 2		/* validation errors */
   		end
   	update bHQBC
   		set Status = @status
   		where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   		end
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcCMTB
   		deallocate bcCMTB
   		end
   
       if @rcode<>0 select @errmsg = @errmsg + char(13) + char(10) + '[bspCMTBVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMTBVal] TO [public]
GO
