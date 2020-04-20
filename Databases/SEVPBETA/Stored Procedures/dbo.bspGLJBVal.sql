SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLJBVal]
/************************************************************************
* Created: ??
* Modified: GG 05/20/98
*           LM changed sum(isnull... to isnull(sum......
*			MV 01/31/03 - #20246 dbl quote cleanup.
*			DC #21384 - 7/8/03  Does not allow out of balance entry to Memo Accounts
* 			DC 23061 - 12/01/03 - Check for ISNull when concatenating fields to create descriptions
*			GG 03/28/08 - #30071 - interco auto journal entries
*			GG 02/18/09 - #132325 - correct bGLJA insert for interco entries
*			GP 08/05/09 - 134681 Add validation for interco AR and AP accounts
*
* Called from GL Batch Process to validate a batch of Auto Journal entries bGLJB. 
* Account distributions added to bGLJA
* Jrnl and GL Reference debit and credit totals must balance.
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* Inputs:
*	@co			Batch Company #
*	@mth		Batch month
*	@batchid	Batch ID#
*
* Outputs:
*	@errmsg		Error message
*	
* Return code:
*	@rcode		0 = success, 1 = error
*
*************************************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
   
as
set nocount on
   
declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
	@adj bYN, @opencursor tinyint, @lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint,
   	@fy bMonth, @batchseq int, @glacct bGLAcct, @entryid smallint, @seq tinyint,
   	@jrnl bJrnl, @glref bGLRef, @description bTransDesc, @amt bDollar, @errno int,
   	@errortext varchar(255), @accttype char(1), @active bYN, @glrefadj bYN, @actdate bDate,
   	@interco bCompany, @errorhdr varchar(30), @apglco bCompany, @arglco bCompany, @arglacct bGLAcct,
   	@apglacct bGLAcct
   
select @rcode = 0, @opencursor = 0

-- validate HQ Batch 
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'GL Auto', 'GLJB', @errmsg output, @status output
if @rcode <> 0  goto bspexit
if @status < 0 or @status > 3
    begin
    select @errmsg = 'Invalid Batch status!', @rcode = 1
    goto bspexit
    end
   
/* validate GL Company and Month */
select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
from dbo.bGLCO with (nolock) where GLCo = @co
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
from dbo.bGLFY with (nolock)
where GLCo = @co and @mth >= BeginMth and @mth <= FYEMO
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
	
-- set InterCo to current GL Co# if null (should not be needed)
update dbo.bGLDB
set InterCo = Co
where Co = @co and Mth = @mth and BatchId = @batchid and InterCo is null
    
/* clear HQ Batch Errors */
delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
/* clear GL Journal Audit */
delete dbo.bGLJA where Co = @co and Mth = @mth and BatchId = @batchid
/*clear HQCC entries */
delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

-- refresh HQ Close Control with an entry for each GL Co# in the Batch
insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, InterCo
from dbo.bGLJB (nolock)
where Co=@co and Mth=@mth and BatchId = @batchid

   
/* declare cursor on GL Journal Batch for validation */
declare bcGLJB cursor for
select BatchSeq, Jrnl, EntryId, Seq, GLRef,Description, GLAcct, Amount, ActDate, InterCo
from dbo.bGLJB (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
/* open cursor */
open bcGLJB
select @opencursor = 1
   
GLJB_loop:		-- validate each batch entry
   fetch next from bcGLJB into @batchseq, @jrnl, @entryid, @seq, @glref, @description, @glacct,
	@amt, @actdate, @interco
   
   if @@fetch_status <> 0 goto GLJB_end

   /* validate GL Journal Batch info for each entry */
   select @errorhdr = 'Seq#' + convert(varchar(6),@batchseq)
    
   /* validate GL Account */
   select @accttype = AcctType, @active = Active
   from dbo.bGLAC (nolock)
   where GLCo = @interco and GLAcct = @glacct
   if @@rowcount = 0
   		begin
   		select @errortext = @errorhdr + ' - Missing GL Account'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto GLJB_loop
   		end
   	if @accttype = 'H'
   		begin
   		select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is a Heading Account.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto GLJB_loop
   		end
   	if @active = 'N'
   		begin
   		select @errortext = @errorhdr + ' - GL Account: ' + @glacct + ' is inactive.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto GLJB_loop
   		end
   	-- validate Journal in current GL Co#
    exec @errno = bspGLJrnlVal @co, @jrnl, @errmsg output
    if @errno <> 0
		begin
     	select @errortext = @errorhdr + ' - ' + @errmsg
     	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	if @rcode <> 0 goto bspexit
   		goto GLJB_loop
     	end
	/* make sure we have a GL Reference */ 
	if isnull(@glref,'') = '' 
     	begin
     	select @errortext = @errorhdr + ' - Must provide a GL Reference.'
     	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     	if @rcode <> 0 goto bspexit
   		goto GLJB_loop
     	end
    /* if GL Reference exists validate adjustment flag */
   	select @glrefadj = Adjust
   	from dbo.bGLRF (nolock)
   	where GLCo = @co and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
   	if @@rowcount > 0 and @glrefadj = 'Y'
   		begin
   		select @errortext = @errortext + ' - GL Reference already used for Adjustment entries.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto GLJB_loop
   		end
    		
	-- #30071 - intercompany validation
   	if @interco <> @co
   		begin 	
      	/* validate GL Company and Month */
     	select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
     	from dbo.bGLCO (nolock)	where GLCo = @interco
     	if @@rowcount = 0
     		begin  		
   			select @errortext = @errorhdr + ' - Invalid GL Co#:' + convert(varchar, @interco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
     	if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
     		begin
     		select @errortext = @errorhdr + ' - Not an open month in GL Co#:' + convert(varchar, @interco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end 
     	/* validate Fiscal Year */
     	select @fy = FYEMO
   		from dbo.bGLFY (nolock)
   		where GLCo = @interco and @mth >= BeginMth and @mth <= FYEMO
     	if @@rowcount = 0
     		begin
     		select @errortext = @errorhdr + ' - Must first add fiscal year in GL Co#:' + convert(varchar, @interco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end	
   		/*Validate Journal*/
     	exec @errno = bspGLJrnlValForGLJE @co, @jrnl, @interco, @errmsg output
     	if @errno <> 0
     		begin
     		select @errortext = @errorhdr + ' - ' + @errmsg
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end	
   		/* if GL Reference exists validate adjustment flag for intercompany*/
     	select @glrefadj = Adjust
   		from dbo.bGLRF (nolock)
     	where GLCo = @interco and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
     	if @@rowcount <> 0 and @glrefadj <> 'N'
     		begin
     		select @errortext = @errorhdr + ' - GL Reference already used for Adjustment entries.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
   		-- validate Interco GL Accounts
   		select @arglco = case when @amt < 0 then @interco else @co end
   		select @apglco = case when @amt < 0 then @co else @interco end
   		select @arglacct = ARGLAcct, @apglacct = APGLAcct
   		from dbo.bGLIA (nolock)
   		where ARGLCo = @arglco and APGLCo = @apglco
   		if @@rowcount = 0
   			begin		
   			select @errortext = @errorhdr + ' - Intercompany accounts not setup for AR GL Co#:' + convert(varchar,@arglco)
   				+ ' and AP GL Co#:' + convert(varchar,@apglco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
   			end
   		if @glacct = @arglacct --134681
			begin
				select @errortext = @errorhdr + ' - Interco: ' + convert(varchar(10),@arglco) + ' AR Account: ' + @arglacct + ' matches Posted GL Account: ' + @glacct
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
			if @rcode <> 0 goto bspexit
			goto GLJB_loop   
			end
		if @glacct = @apglacct --134681
			begin
				select @errortext = @errorhdr + ' - Interco: ' + convert(varchar(10),@apglco) + ' AP Account: ' + @apglacct + ' matches Posted GL Account: ' + @glacct
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
			if @rcode <> 0 goto bspexit
			goto GLJB_loop   
			end         
   		/* validate intercompany AR GL Account */ 	
     	select @accttype = AcctType, @active = Active
     	from dbo.bGLAC (nolock)
     	where GLCo = @arglco and GLAcct = @arglacct
     	if @@rowcount = 0
     		begin
     		select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' not setup in GL Co#:' + convert(varchar, @arglco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
     	if @accttype = 'H'
     		begin
     		select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' is a Heading Account.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
     	if @active = 'N'
     		begin
     		select @errortext = @errorhdr + ' - Interco AR GL Account: ' + @arglacct + ' is inactive.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
   		/* validate intercompany AP GL Account */ 	
     	select @accttype = AcctType, @active = Active
     	from dbo.bGLAC (nolock)
     	where GLCo = @apglco and GLAcct = @apglacct
     	if @@rowcount = 0
     		begin
     		select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' not setup in GL Co#:' + convert(varchar, @arglco)
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
     	if @accttype = 'H'
     		begin
     		select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' is a Heading Account.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
     	if @active = 'N'
     		begin
     		select @errortext = @errorhdr + ' - Interco AP GL Account: ' + @apglacct + ' is inactive.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
     		if @rcode <> 0 goto bspexit
   			goto GLJB_loop
     		end
   		end  		
   		
   	-- all entries involved in an intercompany journal entry should have 'GL JrnlXCo' source
   	select @source = 'GL Auto'	-- source for 'normal' entries
   	if @interco <> @co or (@interco = @co and
   		exists(select 1 from dbo.bGLJB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq
   				and Jrnl = @jrnl and GLRef = @glref and InterCo <> @co))
   		select @source = 'GL JrnlXCo'
   
   	/* update GLJA (Journal Audit) */
   	insert dbo.bGLJA(Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew,
   		EntryId, Seq, Description, Amount, ActDate, InterCo, Source)
   	values (@co, @mth, @batchid, @jrnl, @glref, @glacct, @batchseq, 1,
   			@entryid, @seq, @description, @amt, @actdate, @interco, @source)
   			
   	-- add intercompany entries as needed
   	if @interco <> @co 	
   		begin
   		-- debit intercompany AR GL Account
   		insert dbo.bGLJA(Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew,
   			EntryId, Seq, Description, Amount, ActDate, InterCo, Source) 
       	values (@co, @mth, @batchid, @jrnl, @glref, @arglacct, @batchseq, 1, 
     		@entryid, @seq, @description, abs(@amt), @actdate, @arglco, 'GL JrnlXCo')	-- use absolute value
   		-- credit intercompany AP GL Account
   		insert dbo.bGLJA(Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew, 
   			EntryId, Seq, Description, Amount, ActDate, InterCo, Source) 
   		values (@co, @mth, @batchid, @jrnl, @glref, @apglacct, @batchseq, 1, 
     		@entryid, @seq,	@description, (-1 * abs(@amt)), @actdate, @apglco, 'GL JrnlXCo')	-- use absolute value
   		end
   
   	goto GLJB_loop	-- get next batch entry
   	
GLJB_end:	-- finished with batch entry validation
   	close bcGLJB
   	deallocate bcGLJB	
   	select @opencursor = 0	
   	
   	
/* check Journal/GL Reference totals - unbalanced entries allowed are not allowed  */
select @jrnl = a.Jrnl, @glref = a.GLRef 
from dbo.bGLJA a
join dbo.bGLAC c on c.GLCo = a.InterCo and c.GLAcct = a.GLAcct
where a.Co = @co and a.Mth = @mth and a.BatchId = @batchid and c.AcctType <> 'M'
group by a.InterCo, a.Jrnl, a.GLRef
having isnull(sum(a.Amount),0)<>0
if @@rowcount <> 0
   	begin
   	select @errortext = 'GL Co#: ' + convert(varchar,@interco) + 'Journal: ' + @jrnl + ' and GL Reference: ' + @glref + ' entries don''t balance!'
   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	end
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select top 1 1 from dbo.bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
   	select @status = 2	/* validation errors */

update dbo.bHQBC
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
   		close bcGLJB
   		deallocate bcGLJB
   		end
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJBVal] TO [public]
GO
