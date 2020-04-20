SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_PostGL    Script Date: 8/28/99 9:36:03 AM ******/
CREATE procedure [dbo].[bspARBH1_PostGL]
/***********************************************************
* CREATED BY  : JRE 8/28/97
* MODIFIED By : GG 01/26/99
*		JM 3/4/99 - Set local variable that restricts where clauses
*		against bARBA to records matching the specific @PostGLtype -
*		needed because receipt batches can contain both std receipts
*		and misc receipts which can have different gl interfaces but
*		are processed together in this routine.
*		bc 04/08/99 added credit memos and write offs to PostGLtype input parameter options
*		GG 10/07/99 Fix for null GL Description Control
*		bc 09/21/00 - changed the select statement from max(@variable) to min(@variable) while @BatchSeq is not null in detail code and
*					took out a lot of unneccessary alias code when selecting from a single table.
*		bc 10/25/00 - added check to delete ARBA record before posting if the Amount = 0
*		bc 11/02/00 - added code to handle cross company distributions
*		TJL 04/16/02 - Issue #16468, Correct glinterfacelvl 2, Transaction level posting.
*					replaced psuedo cursors with std cursors. Consistent with AP Entry.
*		TJL 08/08/03 - Issue #22087, Performance mods add NoLocks
*		GWC 04/08/04 - Issue #23061, Adding ISNULLS for building GL Description string
*		TJL 09/30/04 - Issue #25681, Removed Job/Equip from ARCO.GLMiscDetailDesc string
*		TJL 03/17/08 - Issue #125508, Adjust Customer value in GL Description for 10 characters
*
* USAGE:
* 	Posts a validated batch of bARBA GL Amounts
* 	and deletes successfully posted bARBA rows.
*
*  ARTransType = 'X' denotes cross company transactions
*
* INPUT PARAMETERS
*   ARCo        AR Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   DatePosted  Date Batch is Posted
*   PostGLtype  Used to determine which detail level to use
*               must be either 'Invoice','Receipt' or 'MiscCash'
*               Finance charge and Release retainage will use 'Invoice'
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/

(@ARCo bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null,
	@PostGLtype char(10), @Source char(10), @errmsg varchar(255) output)
as

set nocount on
declare @rcode int, @tablename char(20), @opencursorARBA tinyint

select @rcode=0, @opencursorARBA = 0

declare @GLCo bCompany, @GLAcct bGLAcct, @artt char(1),
  	@ARTrans bTrans, @ARTransType char(1), @CustGroup bGroup, @Customer bCustomer,
  	@SortName varchar(15), @Invoice varchar(10), @CheckNo varchar(10), @Job bJob,
  	@Contract bContract, @ActDate bDate, @Description bDesc, @Amount bDollar

declare @glinterfacelvl tinyint, @gltrans bTrans, @Desccontrol varchar(60),
  	@gldetaildesc varchar(60), @jrnl bJrnl, @glsummarydesc varchar(60), @Desc varchar(60),
  	@findidx int, @found varchar(10), @InterfaceDetail char(1), @glref bGLRef
   
if @PostGLtype not in ('Invoice','Cr Memo','Write Off','Adjustment','Receipt','MiscCash','ARFinanceC', 'ARRelease')
	begin
	select @errmsg = 'Invalid PostGLtype!!', @rcode = 1
	goto bspexit
	end
if @Source is null
	begin
	select @errmsg = 'Invalid Source!', @rcode = 1
	goto bspexit
	end

if @PostGLtype in ('Invoice' , 'Cr Memo', 'Write Off', 'Adjustment', 'ARFinanceC', 'ARRelease')
	begin
	select @glinterfacelvl = GLInvLev,
		@jrnl = InvoiceJrnl,
		@glsummarydesc = GLInvSummaryDesc,
		@gldetaildesc = GLInvDetailDesc
	from bARCO with (nolock)
	where ARCo=@ARCo
	end
   
if @PostGLtype='Receipt'
   	begin
   	select @glinterfacelvl = GLPayLev,
   		@jrnl = PaymentJrnl,
   		@glsummarydesc = GLPaySummaryDesc,
   		@gldetaildesc = GLPayDetailDesc
   	from bARCO with (nolock)
   	where ARCo=@ARCo
   	end
   
if @PostGLtype='MiscCash'
   	begin
   	select @glinterfacelvl = GLMiscCashLev,
   		@jrnl = MiscCashJrnl,
   		@glsummarydesc = GLMiscSummaryDesc,
   		@gldetaildesc = GLMiscDetailDesc
   	from bARCO with (nolock)
   	where ARCo=@ARCo
   	end
   
if @glinterfacelvl is null
   	begin
   	select @errmsg = 'GL Interface level may not be null', @rcode = 1
   	goto bspexit
   	end
   
if @jrnl is null and @glinterfacelvl > 0
   	begin
   	select @errmsg = 'Journal may not be null', @rcode = 1
   	goto bspexit
   	end

/* Set local variable that restricts where clauses against bARBA to records
matching the specific @PostGLtype - needed because receipt batches
can contain both std receipts and misc receipts which can have
different gl interfaces but are processed together in this routine. */
select @artt = case when @PostGLtype = 'ARFinanceC' then 'F'
	when @PostGLtype = 'Invoice' then 'I'
	when @PostGLtype = 'Cr Memo' then 'C'
	when @PostGLtype = 'Write Off' then 'W'
	when @PostGLtype = 'Adjustment' then 'A'
	when @PostGLtype = 'MiscCash' then 'M'
	when @PostGLtype = 'Receipt' then 'P'
	when @PostGLtype = 'ARRelease' then 'R'
	end
   
/* update GL using entries from bARBA */
/* no update */
if @glinterfacelvl = 0	 /* no update */
	begin
	delete bARBA 
	where Co = @ARCo and Mth = @Mth and BatchId = @BatchId and (ARTransType = @artt or ARTransType = 'X')
	goto bspexit
	end
   
/* set GL Reference using Batch Id - right justified 10 chars */
select @glref = space(10-datalength(convert(varchar(10),@BatchId))) + convert(varchar(10),@BatchId)

/* summary update */
if @glinterfacelvl = 1	 /* summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail */
	begin
	/* use summary level cursor on AR GL Distributions */
	declare bcARBA cursor local fast_forward for
	select a.GLCo, a.GLAcct,(convert(numeric(12,2),sum(a.Amount)))
	from bARBA a with (nolock)
	join bGLAC g with (nolock) on a.GLCo = g.GLCo and a.GLAcct = g.GLAcct
	where a.Co = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId
		and g.InterfaceDetail = 'N' and (a.ARTransType = @artt or a.ARTransType = 'X')
	group by a.GLCo, a.GLAcct
   
	/* open cursor */
	open bcARBA
	select @opencursorARBA = 1
   
gl_summary_posting_loop:
	fetch next from bcARBA into @GLCo, @GLAcct, @Amount
   
   	if @@fetch_status = -1 goto gl_summary_posting_end
   	if @@fetch_status <> 0 goto gl_summary_posting_loop
   
   	/* begin transaction */
   	begin transaction
   
   	/* get next available transaction # for GLDT */
   	select @tablename = 'bGLDT'
   	exec @gltrans = bspHQTCNextTrans @tablename, @GLCo, @Mth, @errmsg output
   	if @gltrans = 0 goto gl_summary_posting_error
   
   	/* add GL Detail */
   	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
   		ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
   		Adjust, InUseBatchId, Purge)
   	values(@GLCo, @Mth, @gltrans, @GLAcct, @jrnl, @glref, @ARCo, @Source, @DatePosted,
   		@DatePosted, @glsummarydesc, @BatchId, @Amount, 0, 'N', null, 'N')
   
   	if @@rowcount = 0 goto gl_summary_posting_error
   
   	/* delete AR GL Distributions just posted */
   	delete bARBA
   	where Co = @ARCo and Mth = @Mth and BatchId = @BatchId and GLCo = @GLCo and
   		GLAcct = @GLAcct and (ARTransType = @artt or ARTransType = 'X')
   
   	commit transaction
   
   	goto gl_summary_posting_loop
   
gl_summary_posting_error:
   	/* error occured within transaction - rollback any updates and continue */
   	rollback transaction
   
gl_summary_posting_end:	    -- no more rows in summary cursor
	close bcARBA
	deallocate bcARBA
	select @opencursorARBA = 0
   
	end /* interface level=1 */
   
/* Transaction update to GL for everything remaining in bARBA */
/* Transaction level update - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail */

/* use a transaction level cursor on AR GL Distributions */
declare bcARBA cursor local fast_forward for
select a.GLCo, a.GLAcct, a.ARTrans, a.ARTransType, a.CustGroup, a.Customer, a.SortName,
	a.Invoice, a.CheckNo, a.Job, a.Contract, a.ActDate, a.Description,
	(convert(numeric(12,2), sum(a.Amount)))
from bARBA a with (nolock)
join bGLAC g with (nolock) on a.GLCo = g.GLCo and a.GLAcct = g.GLAcct	
where a.Co = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId
	and (ARTransType = @artt or ARTransType = 'X')
group by a.GLCo, a.GLAcct, a.ARTrans, a.ARTransType, a.CustGroup, a.Customer, a.SortName, 
	a.Invoice, a.CheckNo, a.Job, a.Contract, a.ActDate, a.Description
   
/* open cursor */
open bcARBA
select @opencursorARBA = 1

gl_transaction_posting_loop:
	fetch next from bcARBA into @GLCo, @GLAcct, @ARTrans, @ARTransType, @CustGroup, @Customer, @SortName,
		@Invoice, @CheckNo, @Job, @Contract, @ActDate, @Description,
		@Amount
   
   	if @@fetch_status = -1 goto gl_transaction_posting_end
   	if @@fetch_status <> 0 goto gl_transaction_posting_loop
   
   	/* begin transaction */
   	begin transaction
   
   	/* parse out the description */
   	select @Desccontrol = isnull(rtrim(@gldetaildesc),''), @Desc = ''
   	while (@Desccontrol <> '')
		begin
   		select @findidx = charindex('/',@Desccontrol)
   		if @findidx = 0
   			begin
   			select @found = @Desccontrol
   			select @Desccontrol = ''
   			end
   		else
   			begin
   			select @found=substring(@Desccontrol,1,@findidx-1)
   			select @Desccontrol = substring(@Desccontrol,@findidx+1,60)
   			end
   
   		if @found = 'Trans Type' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(8), @ARTransType),'')
   		if @found = 'Trans #'	select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @ARTrans),'')
   		if @found = 'Cust #' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @Customer),'')
   		if @found = 'Sort Name' select @Desc = isnull(@Desc,'') + '/' + isnull(@SortName,'')
   		if @found = 'Invoice' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @Invoice),'')
   		if @found = 'Contract' select @Desc = isnull(@Desc,'') + '/' + isnull(@Contract,'')
   		if @found = 'Desc' select @Desc = isnull(@Desc,'') + '/' + isnull(@Description,'')
   		if @found = 'Check #'	select @Desc = isnull(@Desc,'') + '/' + isnull(@CheckNo,'')
   		-- if @found = 'Job'	select @Desc = isnull(@Desc,'') + '/' + isnull(@Job,'')
   		-- if @found = 'Equip' select @Desc = isnull(@Desc,'') + '/' + isnull(@Equip,'')
   		end
   
   	/* remove leading '/' */
   	if substring(@Desc,1,1)='/' select @Desc = substring(@Desc,2,datalength(@Desc))
   
   	/* get next available transaction # for GLDT */
   	select @tablename = 'bGLDT'
   	exec @gltrans = bspHQTCNextTrans @tablename, @GLCo, @Mth, @errmsg output
   	if @gltrans = 0 goto gl_transaction_posting_error
   
   	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
   		ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
   		Adjust, InUseBatchId, Purge)
	values(@GLCo, @Mth, @gltrans, @GLAcct, @jrnl, @glref, @ARCo, @Source,
   		@ActDate, @DatePosted, @Desc, @BatchId, @Amount, 0, 'N', null, 'N')
   
   	if @@rowcount = 0 goto gl_transaction_posting_error
   
   	/* delete from bARBA */
   	delete bARBA
   	where Co=@ARCo and Mth=@Mth and BatchId=@BatchId and
   		GLCo=@GLCo and GLAcct=@GLAcct and ARTrans = @ARTrans and (ARTransType = @artt or ARTransType = 'X')
   
   	commit transaction
   
   	goto gl_transaction_posting_loop
   
gl_transaction_posting_error:
   	/* error occured within transaction - rollback any updates and continue */
   	rollback transaction
   
gl_transaction_posting_end:	    -- no more rows to process
   	close bcARBA
   	deallocate bcARBA
   	select @opencursorARBA = 0
   
/* make sure GL Audit is empty */
if exists(select top 1 1 from bARBA with (nolock) where Co = @ARCo and Mth = @Mth and BatchId = @BatchId and (ARTransType = @artt or ARTransType = 'X'))
   	begin
   	select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   
bspexit:
	if @opencursorARBA = 1
		begin
		close bcARBA
		deallocate bcARBA
		end
   if @rcode <> 0 select @errmsg = isnull(@errmsg,'')		--+ char(13) + char(10) + '[bspARBH1_PostGL]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_PostGL] TO [public]
GO
