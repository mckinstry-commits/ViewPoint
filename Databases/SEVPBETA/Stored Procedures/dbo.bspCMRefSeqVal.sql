SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMRefSeqVal    Script Date: 8/28/99 9:34:17 AM ******/
   CREATE  proc [dbo].[bspCMRefSeqVal]
   /***********************************************************
    * CREATED BY: JM 5/20/98
    * MODIFIED By : GG 07/25/98
    *
    * USAGE:
    *   Validates CM Reference and CM Ref Seq combination to see if they
    *   are unique by CM Co#, CM Acct, and Transaction Type. 
    * 
    * INPUT PARAMETERS
    *   @cmco      	CM Company 
    *   @mth		Batch Month
    *   @batchid		Batch ID
    *   @batchseq		Seq of current line so we don't mistake same entry
    *   @cmtrans		CM Transaction so we don't mistake current entry
    *   @cmtranstype	Type of entry
    *   @cmacct		CM Account
    *   @cmref		CM Reference
    *   @cmrefseq		CM Reference Seq to validate
    *
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid, 
    *
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
   
   	@cmco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null,
   	@batchseq int = null, @cmtrans bTrans = null, @cmtranstype bCMTransType = null,
   	@cmacct bCMAcct = null, @cmref bCMRef = null, @cmrefseq tinyint, @msg varchar(255) output
   as
   
   set nocount on
   
   declare @rcode int,@dtmth bMonth, @dttrans bTrans,  @dbseq int, @dspmth varchar(8)
   
   select @rcode = 0
   
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   if @cmtranstype is null
   	begin
   	select @msg = 'Missing CM Type!', @rcode = 1
   	goto bspexit
   	end
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   
   	goto bspexit
   	end
   if @cmref is null
   	begin
   	select @msg = 'Missing CM Reference!', @rcode = 1
   	goto bspexit
   	end
   if @cmrefseq is null
   	begin
   	select @msg = 'Missing CM Reference Sequence!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for unique CM Reference/Sequence combination */
   if @cmtrans is null	-- no CM transaction was passed, must be a new entry
   	begin
   	-- check CM Detail
   	select @dttrans = CMTrans, @dtmth = Mth 
   	from bCMDT
        	where CMCo = @cmco and CMAcct = @cmacct and CMTransType = @cmtranstype 
        		and CMRef = @cmref and CMRefSeq = @cmrefseq
   	end
   else			-- CM transaction indicates an existing CM Detail entry 
   	begin
   	select @dttrans = CMTrans, @dtmth = Mth 
   	from bCMDT
   
        	where CMCo = @cmco and CMTransType = @cmtranstype and CMAcct = @cmacct
           	and CMRef = @cmref and CMRefSeq = @cmrefseq and (CMTrans <> @cmtrans and Mth <> @mth)
   	end
   	
   if @@rowcount <> 0
   	begin
   	select @dspmth = convert(varchar(8),@dtmth,1)
   	select @dspmth = substring(@dspmth,1,3) + substring(@dspmth,7,2) 
   	select @msg = 'CM Reference ' + @cmref + ' and Seq# ' + convert(varchar(4),@cmrefseq) + ' already used on Trans# ' +
   		convert(varchar(8),@dttrans) + '.  Posted in ' + @dspmth
   	select @rcode = 1 
   	goto bspexit
   	end
   
    
   /* if BatchId passed, check for uniqueness within the current batch */
   if @batchid is not null 
   	begin
   	if @mth is null
   		begin
   		select @msg = 'Missing Batch Month.', @rcode = 1
   		goto bspexit
   		end
   	if @batchseq is null
   		begin
   		select @msg = 'Missing Batch Sequence #.', @rcode = 1
   		goto bspexit
   		end
   	 
   	select @dbseq = BatchSeq
   	from bCMDB
          	where Co = @cmco and Mth = @mth and BatchId = @batchid and BatchSeq <> @batchseq
   		and CMAcct = @cmacct and CMTransType = @cmtranstype and CMRef = @cmref and CMRefSeq = @cmrefseq 
   	if @@rowcount <> 0
   		begin
   
   	   	select @msg = 'CM Reference ' + @cmref + ' and Seq# ' + convert(varchar(4),@cmrefseq) +
   	   		' already used in this Batch on Seq#' + convert(varchar(6),@dbseq)
   	   	select @rcode = 1
   	   	goto bspexit
   	  	end
          	end 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMRefSeqVal] TO [public]
GO
