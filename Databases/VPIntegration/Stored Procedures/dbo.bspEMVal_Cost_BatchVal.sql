SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Cost_BatchVal    Script Date: 8/28/99 9:36:14 AM ******/
CREATE   procedure [dbo].[bspEMVal_Cost_BatchVal]
/***********************************************************
* CREATED BY: JM 3/6/99
* MODIFIED By : ae 9/3/99
*             JM 12/29/99 - Added clear of prior bEMIN entries
*             for the applicable EMCo/Mth/BatchId.
*             JM 2/22/00 - Changed read of TableName passed to bspHQBatchProcessVal
*               to include EMTransType for EMAdj source to segment Fuel transactions
*               to EMBZGrid and all others to EMBF.
*             DanF 04/07/00 Added Source 'EMTime'
*				TV 02/11/04 - 23061 added isnulls
*				GF 01/25/2008 - issue #126860 remove reference to 'EMBZGrid'
*
*
* USAGE:
* 	Called by bspEMVal_Cost to validate batch data,
*	set HQ Batch status. clear HQ Batch Errors. clear
*	GL Detail Audit. and clear and refresh HQCC entries.
*
* INPUT PARAMETERS
*	EMCo        EM Company
*	Month       Month of batch
*	BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*	@errmsg     if something went wrong
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
    @co bCompany,
    @mth bMonth,
    @batchid bBatchID,
    @source bSource,
    @errmsg varchar(255) output
    as
    declare @checktable varchar(20),
    	@emglco bCompany,
      @emtranstype varchar(10),
    	@fy bMonth,
    	@lastglmth bMonth,
    	@lastsubmth bMonth,
    	@maxopen tinyint,
    	@rcode int,
    	@status tinyint
    set nocount on
    select @rcode = 0
   
    /* Verify parameters passed in. */
    if @co is null
    	begin
    	select @errmsg = 'Missing Batch Company!', @rcode = 1
    	goto bspexit
    	end
    if @mth is null
    	begin
    	select @errmsg = 'Missing Batch Month!', @rcode = 1
    	goto bspexit
    	end
    if @batchid is null
    	begin
    	select @errmsg = 'Missing BatchID!', @rcode = 1
    	goto bspexit
    	end
    if @source is null
    	begin
    	select @errmsg = 'Missing Batch Source!', @rcode = 1
    	goto bspexit
    	end
   
    /* Validate Source. */
    if @source not in ('EMAdj', 'EMParts', 'EMDepr', 'EMAlloc', 'EMTime','EMFuel')
    	begin
    	select @errmsg = 'Invalid Batch Source for this validation procedure!', @rcode = 1
    	goto bspexit
    	end



/* Validate HQ Batch. Special validation because the EMAdj Source can have multiple TableNames in HQBC. */
select @checktable = TableName from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0 or @checktable <> 'EMBF' -- error
	begin
	select @errmsg = 'Invalid HQBC.TableName!' + isnull(@checktable,''), @rcode = 1
	goto bspexit
	end

      exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, @checktable, @errmsg output, @status output
      if @rcode <> 0
         begin
         select @rcode = 1
         goto bspexit
         end
      if @status < 0 or @status > 3
         begin
         select @errmsg = 'Invalid Batch status!', @rcode = 1
         goto bspexit
         end
   
    /* Validate EMCo. */
    select @emglco = GLCo from bEMCO where EMCo = @co
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid EM Company ' + isnull(convert(varchar(2),@emglco),'') + '!', @rcode = 1
    	goto bspexit
    	end
   
    /* Validate GL Company and Month and get info from GLCO. */
    select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen from bGLCO where GLCo = @emglco
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid GL Company ' + isnull(convert(varchar(2),@emglco),'') + '!', @rcode = 1
    	goto bspexit
    	end
    if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
    	begin
    	select @errmsg = 'Not an open month!', @rcode = 1
    	goto bspexit
    	end
   
    /* Validate Fiscal Year. */
    select @fy = FYEMO from bGLFY where GLCo = @emglco and @mth >= BeginMth and @mth <= FYEMO
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid Fiscal Year!', @rcode = 1
    	goto bspexit
    	end
   
    /* Set HQ Batch status to 1 (validation in progress). */
    update bHQBC set Status = 1 where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	end
   
    /* Clear HQ Batch Errors. */
    delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* Clear GL Detail Audit. */
    delete bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid
   
     /* Clear bEMIN. */
    delete bEMIN where EMCo = @co and Mth = @mth and BatchId = @batchid
   
    /* Clear and refresh HQCC entries. */
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    insert into bHQCC(Co, Mth, BatchId, GLCo) select distinct Co, Mth, BatchId, GLCo from bEMBF where Co=@co and Mth=@mth and BatchId=@batchid
   
    bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_BatchVal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_BatchVal] TO [public]
GO
