SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMRefVal    Script Date: 11/13/2001 1:10:01 PM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspCMRefVal    Script Date: 8/28/99 9:34:17 AM ******/
    
    CREATE   proc [dbo].[bspCMRefVal]
    /***********************************************************
     * CREATED BY: SE   8/20/96
     * MODIFIED By : GG 07/25/98
     *
     * USAGE:
     *   Used by the CM Posting form to validate CM Reference. Checks CM Detail
     *   and current CM Entry batch.
     * 
     * INPUT PARAMETERS
     *   @cmco     		CM Co 
     *   @mth       	Batch Month
     *   @batchid   	Batch ID
     *   @batchseq  	Seq of current line so we don't mistake same entry
     *   @cmtrans   	CM Transaction so we don't mistake current entry
     *   @cmtranstype      	0=adjust, 1=check, 2=deposit, 3=eft
     *   @cmacct		CM Account
     *   @cmref    		CM Reference to validate
     *
     * OUTPUT PARAMETERS
     *   @errmsg     	error message if invalid,
     * 
     * RETURN VALUE
     *   0 		success - CM Reference is unique
     *   1		fatal error
     *   2 		CM Reference is not unique
     *****************************************************/ 
    
    	@cmco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null,
    	@batchseq int = null, @cmtrans bTrans = null, @cmtranstype bCMTransType = null,
    	@cmacct bCMAcct = null, @cmref bCMRef = null, @errmsg varchar(255) output
    as
    
    set nocount on
    
    declare @rcode int, @dtmth bMonth, @dttrans bTrans, @dbseq int, @dspmth varchar(8)
    
    select @rcode = 0
    
    if @cmco is null
    	begin
    	select @errmsg = 'Missing CM Company!', @rcode = 1
    	goto bspexit
    	end
    if @cmtranstype is null
    	begin
    	select @errmsg = 'Missing CM Type!', @rcode = 1
    	goto bspexit
    	end
    if @cmacct is null
    	begin
    	select @errmsg = 'Missing CM Account!', @rcode = 1
    	goto bspexit
    	end
    
    if @cmref is null
    	begin
    	select @errmsg = 'Missing CM Reference!', @rcode = 1
    	goto bspexit
    	end
    
    /* check for unique CM Reference */
    if @cmtrans is null	-- no CM transaction was passed, must be a new entry
    	begin
    	-- check CM Detail
    	select @dttrans = CMTrans, @dtmth = Mth
    	from bCMDT
    	where CMCo = @cmco and CMAcct = @cmacct and CMTransType = @cmtranstype and CMRef = @cmref
    	end
    else			-- CM transaction indicates an existing CM Detail entry
    	begin
    	select @dttrans = CMTrans, @dtmth = Mth 
    	from bCMDT
         	where CMCo = @cmco and CMTransType = @cmtranstype and CMAcct = @cmacct
            	and CMRef = @cmref and (CMTrans <> @cmtrans and Mth <> @mth)	-- exclude itself
            end
    
            	
    if @@rowcount <> 0
    	begin
    	select @dspmth = convert(varchar(8),@dtmth,1)
    	select @dspmth = substring(@dspmth,1,3) + substring(@dspmth,7,2) 
    	select @errmsg = 'CM Reference ' + @cmref + ' already used on Trans#:' + convert(varchar(8),@dttrans) + 
    		'.  Posted in '+ @dspmth
    	select @rcode = 2
    	goto bspexit
    	end
    
     
    /* if BatchId passed, check for uniqueness within the current batch */
    if @batchid is not null 
    	begin
    	if @mth is null
    		begin
    		select @errmsg = 'Missing Batch Month.', @rcode = 1
    		goto bspexit
    		end
    	if @batchseq is null
    		begin
    		select @errmsg = 'Missing Batch Sequence #.', @rcode = 1
    		goto bspexit
    		end
    		 
           	select @dbseq = BatchSeq 
           	from bCMDB
            where Co = @cmco and Mth = @mth and BatchId = @batchid and BatchSeq <> @batchseq
    		and CMAcct = @cmacct and CMTransType = @cmtranstype and CMRef = @cmref
    	if @@rowcount <> 0 
    		begin
    	   	select @errmsg = 'CM Reference ' + @cmref + ' already used in this Batch on Seq# ' + convert(varchar(6),@dbseq)
    		select @rcode = 2
    	   	goto bspexit
    	  	end
           	end 
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMRefVal] TO [public]
GO
