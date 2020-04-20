SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMNextRefSeq    Script Date: 8/28/99 9:34:16 AM ******/
   CREATE  proc [dbo].[bspCMNextRefSeq]
   /***********************************************************
    * CREATED BY: JM 5/20/98
    * MODIFIED By: GG 07/25/98
    *
    * USAGE:
    *   Returns next available CM Reference Sequence for a given CM Co#,
    *   CM Account, Transaction Type, and CM Reference.  Check both CM Detail
    *   and the current batch in CM Detail Batch.  Only called if CM Reference
    *   is not unique, so Seq# returned will always be >= 1
    * 
    * INPUT PARAMETERS
    *   @cmco      	CM Co#
    *   @mth		Batch Month
    *   @batchid		Batch ID
    *   @batchseq		Seq of current entry so we don't mistake same entry
    *   @cmtranstype	Transaction type, 0=adj, 1=check, 2=deposit, 3=eft
    *   @cmacct		CM Account
    *   @cmref		CM Reference
    *   
    * OUTPUT PARAMETERS
    *   @cmrefseq    	The next available CM Reference Seq#
    *   @msg     		Error message if invalid 
    *
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
   
   	(@cmco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	@cmtranstype bCMTransType = null, @cmacct bCMAcct = null, @cmref bCMRef = null, 
   	@cmrefseq tinyint output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @maxdbseq tinyint, @maxdtseq tinyint,@maxseq tinyint
   
   select @rcode = 0, @cmrefseq = 0
   
   
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @msg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @msg = 'Missing Batch ID!', @rcode = 1
   	goto bspexit
   	end
   if @cmtranstype is null
   	begin
   	select @msg = 'Missing CM Transaction Type!', @rcode = 1
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
   
   -- get highest Seq# in use from CM Detail
   select @maxdtseq = isnull(max(CMRefSeq),0)
   from bCMDT
   where CMCo = @cmco and CMAcct = @cmacct and CMTransType = @cmtranstype 	and CMRef = @cmref
   
   -- get highest Seq# in use from CM Detail Batch
   select @maxdbseq = isnull(max(CMRefSeq),0)
   from bCMDB
   where Co = @cmco and Mth = @mth and BatchId = @batchid and CMAcct = @cmacct 
          	and CMTransType = @cmtranstype and CMRef = @cmref
          	
   select @maxseq = @maxdtseq
   if @maxdbseq > @maxseq select @maxseq = @maxdbseq       	
   select @cmrefseq = @maxseq + 1
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMNextRefSeq] TO [public]
GO
