SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLRBInitialize]
/************************************************************************
* CREATED: ??
* MODIFIED: GG 05/04/98
*			MV 01/31/03 - #20246 dbl quote cleanup.
*			DC 12/01/03 #23061 - Check for ISNull when concatenating fields to create descriptions
*			DANF 03/15/05 - #27294 - Remove scrollable cursor.
*
* This procedure is used by the GL Reversal Entry program to initialize
* reversal entries into the GLRB batch.            
*
* Checks batch info in bHQBC, and transaction info in bGLDT.
* Adds entry to next available Seq# in bGLRB
*
* GLRB insert trigger will update InUseBatchId in bGLDT
*
* Pass in Co, Mth, BatchId, Journal, Actual Date, and optionally a GL Reference list.
* If you pass in null for reference list then it will initialize all References.
*
* Jrnl must be a Reversal Journal
* Mth must be > origmth
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
   
   	@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @jrnl bJrnl = null,
	@actdate bDate = null, @glreflist varchar(250) = null, @origmth bMonth = null,
	@errmsg varchar(255) output
   	
as
set nocount on
   
declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
	@origgltrans bTrans, @glacct bGLAcct, @dglref bGLRef, @revjrnl bJrnl, @origdate bDate,
    @desc bTransDesc,@destdesc bTransDesc, @destglref bGLRef, @amt bDollar, @inusebatchid bBatchID, @seq int
   	 
declare @cursoropen tinyint, @addcount int, @skipcount int
   
select @rcode = 0, @cursoropen=0
   
if @mth <= @origmth
	begin
    select @errmsg = 'The Month you''re posting to must be greater than the original month!', @rcode = 1
   	goto bspexit
   	end
      
/* validate HQ Batch */
select @source = Source, @tablename = TableName, @inuseby = InUseBy, @status = Status
from dbo.bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
	goto bspexit
	end
if @source <> 'GL Rev'
    begin
	select @errmsg = 'Invalid Batch source - must be ''GL Rev''!', @rcode = 1
	goto bspexit
	end
if @tablename <> 'GLRB'
	begin
	select @errmsg = 'Invalid Batch table name - must be ''bGLRB''!', @rcode = 1
	goto bspexit
	end
if @inuseby <> SUSER_SNAME()
   	begin
   	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'MISSING: @inuseby'), @rcode = 1
   	goto bspexit
   	end
if @status <> 0 
   	begin
   	select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
   	goto bspexit
   	end
   
select @revjrnl=RevJrnl
from dbo.bGLJR (nolock)
where GLCo=@co and Jrnl=@jrnl
if @revjrnl is null 
	begin 
    select @errmsg = 'Selected journal does not have an associated reversing journal!', @rcode=1
    goto bspexit
    end
   
if @glreflist is null
	begin
      /* Create cursor on qualifying transactions and then pull one at a time */
   	declare GLRB_insert cursor local fast_forward for
	select GLTrans, Description, GLAcct, GLRef, ActDate, Amount, InUseBatchId
    from dbo.bGLDT with (nolock)
    where GLCo=@co and Mth=@origmth and @jrnl=Jrnl and RevStatus = 0 and InUseBatchId is null
    end
else
    begin
    /* Create cursor on qualifying transactions and then pull one at a time */
   	declare GLRB_insert cursor local fast_forward for
	select GLTrans, Description, GLAcct, GLRef, ActDate, Amount, InUseBatchId
    from dbo.bGLDT with (nolock) 
    where GLCo=@co and Mth=@origmth and @jrnl=Jrnl and RevStatus = 0 and InUseBatchId is null 
		and charindex('' + rtrim(GLRef) + '',@glreflist) <>0 
    end
   
open GLRB_insert
select @cursoropen = 1, @addcount=0, @skipcount=0
   
process_loop:
	fetch next from GLRB_insert into @origgltrans, @desc, @glacct, @dglref, @origdate,
		@amt, @inusebatchid
   	if (@@fetch_status <> 0) goto process_loop_end
   
    if @inusebatchid is not null 
		begin
        select @skipcount=@skipcount+1
        goto process_loop 
        end
   
	select @destdesc = 'Rev:' + @desc, @destglref=rtrim(@dglref)+'R'
   
    /* get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0)+1
	from dbo.bGLRB with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* add GL transaction to batch */
    insert into bGLRB (Co, Mth, BatchId, BatchSeq, OrigMonth, OrigDate, OrigGLTrans, Jrnl, GLRef,
   	       Description, GLAcct, Amount, ActDate)
    values (@co, @mth, @batchid, @seq, @origmth, @origdate, @origgltrans, @revjrnl, @destglref,
   	        @destdesc, @glacct, (@amt*-1), @actdate)
    if @@rowcount = 1
   		begin
      	Select @addcount = @addcount+1
   	    end
   
    goto process_loop
   
process_loop_end: 
	select @errmsg = convert(varchar(6), @addcount) + ' entries successfully initialized. '
     
bspexit:
	if @cursoropen=1
		begin
        close GLRB_insert
   		deallocate GLRB_insert
        end
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRBInitialize] TO [public]
GO
