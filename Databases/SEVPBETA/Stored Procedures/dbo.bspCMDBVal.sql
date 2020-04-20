SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMDBVal    Script Date: 8/28/99 9:36:09 AM ******/
CREATE   procedure [dbo].[bspCMDBVal]
/***********************************************************
* CREATED BY:	SE	08/20/1996
* MODIFIED By:	GG	12/02/1997
*				JRE	06/08/1998	- changed check for @oldamt to isnull(@oldamt,0)
*				LM	03/30/1999	- changed sum(isnull(amount... to isnull(sum(isnull...
*				GG	05/19/2000	- include CM Ref Seq in uniqueness check - general cleanup
*				ES	04/09/2004	- #24226 Use GLCo instead of Co when validating fiscal year.
*				CHS	04/22/2011	- B-03437 add TaxCode
* 
* USAGE:
* Validates each entry in bCMDB for a selected batch - must be called
* prior to posting the batch.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* GL Account distributions added to bCMDA
*
* Jrnl and GL Reference debit and credit totals must balance.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*   @co            CM Co
*   @mth           Month of batch
*   @batchid       Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0   success
*   1   fail
        *****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output

       as
       set nocount on
   
       declare @rcode int, @errortext varchar(255), @status tinyint, @opencursor tinyint,
       @lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint, @accttype char(1), @active bYN, @fy bMonth,
       @seq int, @transtype char(1), @cmtrans bTrans, @cmacct bCMAcct, @cmtranstype bCMTransType,
       @actdate bDate, @description bDesc,	@amt bDollar, @cmref bCMRef, @cmrefseq tinyint,
       @payee varchar(20), @glco bCompany, @cmglacct bGLAcct, @glacct bGLAcct, @void bYN,
       @oldcmacct bCMAcct, @oldactdate bDate, @olddesc bDesc,  @oldamt bDollar, @oldcmref bCMRef,
       @oldcmrefseq tinyint, @oldpayee varchar(20), @oldglco bCompany, @oldcmglacct bGLAcct,
       @oldglacct bGLAcct, @oldvoid bYN, @dtcmacct bCMAcct, @dtcmtranstype bCMTransType,
       @dtactdate bDate, @dtdesc bDesc, @dtamt bDollar, @dtcmref bCMRef, @dtcmrefseq tinyint,
       @dtpayee varchar(20), @dtglco bCompany, @dtcmglacct bGLAcct, @dtglacct bGLAcct, @dtvoid bYN,
       @errorstart varchar(50), @subtype char(1), @stmtdate bDate, @inusebatchid bBatchID, @cmglco bCompany,
       @jrnl bJrnl, @TaxGroup bGroup, @TaxCode bTaxCode, @OldTaxGroup bGroup, @OldTaxCode bTaxCode
   
       select @rcode = 0, @opencursor = 0
   
       /* validate Batch Control entry */
       exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'CM Entry', 'CMDB', @errmsg output, @status output
       if @rcode <> 0 goto bspexit
       if @status < 0 or @status > 3
           begin
           select @errmsg = 'Invalid Batch status!', @rcode = 1
           goto bspexit
           end
   
       /* get GL Company from CM Company */
       select @cmglco = GLCo, @jrnl=Jrnl from bCMCO where CMCo = @co
       if @@rowcount = 0
       	begin
       	select @errmsg = 'Invalid CM Company #', @rcode = 1
       	goto bspexit
       	end
   
       /* validate GL Company and Month */
       select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
       from bGLCO where GLCo = @cmglco
       if @@rowcount = 0
       	begin
       	select @errmsg = 'Invalid GL Company #', @rcode = 1
       	goto bspexit
       	end
       if not exists (select * from bGLJR where GLCo=@cmglco and Jrnl=@jrnl)
       	begin
       	select @errmsg = 'Invalid GL Journal.  Check your company setup. ', @rcode = 1
       	goto bspexit
       	end
       if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
       	begin
       	select @errmsg = 'Not an open month', @rcode = 1
       	goto bspexit
       	end
   
       /* validate Fiscal Year */
       select @fy = FYEMO from bGLFY
       	where GLCo = @cmglco and @mth >= BeginMth and @mth <= FYEMO
       if @@rowcount = 0
       	begin
       	select @errmsg = 'Must first add Fiscal Year', @rcode = 1
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
   
       /* clear GL Detail Audit */
       delete bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
   
       /*clear and refresh HQCC entries */
       delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
       insert into bHQCC(Co, Mth, BatchId, GLCo)
            select distinct Co, Mth, BatchId, GLCo from bCMDB
              where Co=@co and Mth=@mth and BatchId=@batchid
   
   
       /* declare cursor on CM Detail Batch for validation */
       declare bcCMDB cursor for
       select BatchSeq, BatchTransType, CMTrans, CMAcct, CMTransType, ActDate, Description,
           Amount, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, GLAcct, Void, OldCMAcct, OldActDate,
           OldDesc, OldAmount, OldCMRef, OldCMRefSeq, OldPayee, OldGLCo, OldCMGLAcct, OldGLAcct, OldVoid,
           TaxGroup, TaxCode, OldTaxGroup, OldTaxCode
       from bCMDB
       where Co = @co and Mth = @mth and BatchId = @batchid
   
       /* open cursor */
       open bcCMDB
   
       /* set open cursor flag to true */
       select @opencursor = 1
   
       CMDB_loop:  -- loop through each batch entry
           fetch next from bcCMDB into @seq, @transtype, @cmtrans, @cmacct, @cmtranstype, @actdate,
               @description, @amt, @cmref, @cmrefseq, @payee, @glco, @cmglacct, @glacct, @void,
       	    @oldcmacct, @oldactdate, @olddesc, @oldamt, @oldcmref, @oldcmrefseq, @oldpayee,
               @oldglco, @oldcmglacct, @oldglacct, @oldvoid, @TaxGroup, @TaxCode, @OldTaxGroup, @OldTaxCode
   
           if @@fetch_status <> 0 goto CMDB_loop_end
   
       	/* validate CM Detail Batch info for each entry */
       	select @errorstart = 'Seq#' + convert(varchar(6),@seq)
       	
       	/* validate TaxCode */
       	IF (@TaxGroup IS NOT NULL) AND (@TaxCode IS NOT NULL)
       		BEGIN
       		IF NOT EXISTS(SELECT TOP 1 1 FROM bHQTX t WHERE t.TaxGroup = @TaxGroup and t.TaxCode = @TaxCode)
       			BEGIN
				SELECT @errortext = @errorstart + ' - CM Tax Group / Tax Code not found in HQTX.'
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
				IF @rcode <> 0 GOTO bspexit
				GOTO CMDB_loop       			
       			END
       		END
   
       	/* validate transaction type */
       	if @transtype not in ('A','C','D')
       		begin
       		select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
               goto CMDB_loop
       		end
   
       	/* validation specific to Add types */
       	if @transtype = 'A'
       		begin
       		/* check CM Trans# */
       		if @cmtrans is not null
       			begin
       			select @errortext = @errorstart + ' - (New) entries may not reference a CM Transaction #.'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
   
       		/* all old values must be null */
       		if @oldcmacct is not null or @oldactdate is not null or @olddesc is not null or isnull(@oldamt,0) <> 0 or
                          	@oldcmref is not null or @oldcmrefseq is not null or @oldpayee is not null or
                         	@oldglco is not null or @oldcmglacct is not null or @oldglacct is not null or @oldvoid is not null
       			begin
       			select @errortext = @errorstart + ' - Old information in batch must be null for Add entries.'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       			if @rcode<>0 goto bspexit
                   goto CMDB_loop
       			end
   
       		/* validate CM Transaction Type - 0=Adj, 1=Check, 2=Deposit */
       		if @cmtranstype not in (0,1,2)
       			begin
       		    select @errortext = @errorstart + ' - Invalid CMTransType for this batch.  Must be 0,1, or 2.'
       		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		  	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       		   	end
   
       		/* check CM Ref/Ref Seq uniqueness in CM Detail */
       		if exists (select * from bCMDT where CMCo = @co and CMAcct = @cmacct and
       					CMTransType = @cmtranstype and CMRef = @cmref and CMRefSeq = @cmrefseq)
       			begin
                   select @errortext = @errorstart + ' - CM Reference/Sequence already exists in CM Detail.'
       	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0 goto bspexit
                   goto CMDB_loop
             		end
   
       		/* check CM Ref/Ref Seq uniqueness in current batch */
       		if exists (select * from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid
       			and BatchSeq <> @seq and CMAcct = @cmacct and CMTransType = @cmtranstype
       			and CMRef = @cmref and CMRefSeq = @cmrefseq)
       			begin
                   select @errortext = @errorstart + ' - CM Reference/Sequence not unique within this batch.'
       	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0 goto bspexit
                   goto CMDB_loop
             		end
       		end
   
       	/* validation specific for Change and Delete types */
       	if @transtype = 'C' or @transtype = 'D'
       		begin
       		/* get existing values from CMDT */
       	    select @dtcmacct = CMAcct, @stmtdate = StmtDate, @dtcmtranstype = CMTransType,
       			@dtactdate = ActDate, @dtdesc = Description, @dtamt = Amount, @dtcmref = CMRef,
       			@dtcmrefseq = CMRefSeq, @dtpayee = Payee, @dtglco = GLCo, @dtcmglacct = CMGLAcct,
       			@dtglacct = GLAcct, @dtvoid = Void, @inusebatchid = InUseBatchId
       		from bCMDT
               where CMCo = @co and Mth = @mth and CMTrans = @cmtrans
       	    if @@rowcount = 0
                   begin
        		 	select @errortext = @errorstart + ' - Missing CM Transaction#.'
       		  	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		  	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
       		/* check if already cleared */
       		if @stmtdate is not null
       			begin
       			select @errortext = @errorstart + ' - Existing CM Transaction has already been cleared.'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		  	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
       		/* check In Use Batch info */
       		if @inusebatchid <> @batchid
       			begin
       			select @errortext = @errorstart + ' - Existing CM Transaction has not been assigned to this batch.'
       			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		  	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
       		/* make sure old values in batch match existing values in detail */
       	    if @dtcmacct <> @oldcmacct or @dtactdate <> @oldactdate or isnull(@dtdesc,'') <> isnull(@olddesc,'')
                   or @dtamt <> @oldamt or @dtcmref <> @oldcmref or @dtcmrefseq <> @oldcmrefseq
                   or isnull(@dtpayee,'') <> isnull(@oldpayee,'') or @dtglco <> @oldglco or @dtcmglacct <> @oldcmglacct
                   or isnull(@dtglacct,'') <> isnull(@oldglacct,'') or @dtvoid <> @oldvoid
        			begin
       		 	select @errortext = @errorstart + ' - Old information in batch does not match existing info in CM Detail.'
       		 	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		 	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
       		/* check for changes to CMTransType */
               if @cmtranstype <> @dtcmtranstype
       	        begin
                   select @errortext = @errorstart + ' - CM Transaction Type cannot be changed.'
       		 	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		 	if @rcode <> 0 goto bspexit
                   goto CMDB_loop
       			end
   
       		/* check CM Ref/Ref Seq uniqueness in CM Detail */
       		if exists (select * from bCMDT where CMCo = @co and CMAcct = @cmacct and
       			CMTransType = @cmtranstype and CMRef = @cmref and CMRefSeq = @cmrefseq
                   and (Mth <> @mth or @cmtrans <> CMTrans))
                   begin
              select @errortext = @errorstart + ' - CM Reference/Ref Seq already exists in CM Detail.'
       	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0 goto bspexit
                   goto CMDB_loop
             		end
   
       		/* check CM Ref/Ref Seq uniqueness in current batch */
       		if exists (select * from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid
       			and BatchSeq <> @seq and CMAcct = @cmacct and CMTransType = @cmtranstype
                   and CMRef = @cmref and CMRefSeq = @cmrefseq)
       			begin
                   select @errortext = @errorstart + ' - CM Reference not unique within this batch.'
       	  	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0 goto bspexit
                   goto CMDB_loop
             		end
       		end
   
       	/* validation that applies to all types: Add, Change, and Delete */
   
       	/* validate CM Account */
       	if not exists (select * from bCMAC where CMCo = @co and CMAcct = @cmacct)
       		begin
       		select @errortext = @errorstart + ' - Invalid CM Account.'
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
               goto CMDB_loop
       		end
       	/* make sure posted and CM GL Accounts aren't the same */
       	if isnull(@glacct,'') = @cmglacct
       		begin
       		select @errortext = @errorstart + ' - Posted GL account cannot be the same as the CM GL Account.'
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
               goto CMDB_loop
       		end
   
           -- validate posted GL Account - subledger type must be null
           exec @rcode = bspGLACfPostable @glco, @glacct, 'N', @errmsg output
           if @rcode <> 0
       		begin
       		select @errortext = @errorstart + ' ' + @errmsg
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
               goto CMDB_loop
       		end
   
       	-- validate CMGLAcct Account
       	exec @rcode = bspCMGLAcctVal @co, @cmglacct, @errmsg output
       	if @rcode <> 0
       		begin
       		select @errortext = @errorstart + ' - ' + @errmsg
       		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       		if @rcode <> 0 goto bspexit
               goto CMDB_loop
       		end
   
       	update_audit:	/* update GL Detail Audit  - only update if Amount, GLAcct or Void flag changes */
              if (@transtype <> 'C') or (@oldglacct <> @glacct or @oldamt <> @amt or @oldvoid <> @void or @oldcmglacct <> @cmglacct)
                  begin
       	    	if @transtype <> 'A' and @oldvoid = 'N' and @oldamt <> 0	/* don't add GL distributions for voided entries */
                      begin
        			    /* insert 'old' entry for posted GL Account - don't reverse sign of offsetting entry */
       			    insert into bCMDA (CMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
       		       		CMTrans, CMAcct, CMTransType, ActDate, Description, Amount, CMRef, Payee)
        			    values (@co, @mth, @batchid, @oldglco, @oldglacct, @seq, 0, @cmtrans,
       		       		@oldcmacct, @cmtranstype, @oldactdate, @olddesc, @oldamt, @oldcmref, @oldpayee)
   
       			    /* insert 'old' entry for CM GL Account */
       			    update bCMDA
       				set Amount = Amount + (-1 * @oldamt)
       				where CMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @oldglco
       				   and GLAcct = @oldcmglacct and BatchSeq = @seq and OldNew = 0
       			    if @@rowcount = 0
       				   begin
       				   insert into bCMDA (CMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
       					  CMTrans, CMAcct, CMTransType, ActDate, Description, Amount, CMRef, Payee)
       				   values (@co, @mth, @batchid, @oldglco, @oldcmglacct, @seq, 0, @cmtrans,
       					  @oldcmacct, @cmtranstype, @oldactdate, @olddesc,  (-1 * @oldamt),	/* reverse sign for old amount */
       					  @oldcmref, @oldpayee)
       	       		   end
       			    end
   
                  if @transtype <> 'D' and  @void = 'N' and @amt <> 0	/* don't add GL distributions for voided entries */
                      begin
        			    /* insert 'new' entry for CM GL Account */
       			    insert into bCMDA (CMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
                          CMTrans, CMAcct, CMTransType, ActDate, Description, Amount, CMRef, Payee)
       	            values (@co, @mth, @batchid, @glco, @cmglacct, @seq, 1, @cmtrans,
       		       	    @cmacct, @cmtranstype, @actdate, @description, (@amt), @cmref, @payee)
   
         	            /* insert 'new' entry for posted GL Account */
       			    update bCMDA
       			    set Amount = Amount + (-1 * @amt)
       			    where CMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
       				   and GLAcct = @glacct and BatchSeq = @seq and OldNew = 1
       			    if @@rowcount = 0
       				   begin
       				   insert into bCMDA (CMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew,
       		       		    CMTrans, CMAcct, CMTransType, ActDate, Description, Amount, CMRef, Payee)
       				   values (@co, @mth, @batchid, @glco, @glacct, @seq, 1, @cmtrans,
       		       		    @cmacct, @cmtranstype, @actdate, @description, (-1 * @amt), @cmref, @payee)
       				   end
               	  end
                end
   
               goto CMDB_loop  -- next batch entry
   
       CMDB_loop_end:
       	close bcCMDB
       	deallocate bcCMDB
          select @opencursor = 0
   
       /* check GL totals - This should always be in balance  */
       select @glco = GLCo from bCMDA where CMCo = @co and Mth = @mth and BatchId = @batchid
       	group by GLCo
        	having isnull(sum(Amount),0) <> 0
       if @@rowcount <> 0
           begin
           select @errortext =  'Debit and credit entires within this batch do not balance!'
           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           end
   
       /* check HQ Batch Errors and update HQ Batch Control status */
       select @status = 3	/* valid - ok to post */
       if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
       	begin
       	select @status = 2	/* validation errors */
       	end
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
       		close bcCMDB
       		deallocate bcCMDB
       		end
   
       	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMDBVal] TO [public]
GO
