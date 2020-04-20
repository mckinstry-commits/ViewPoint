SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCMRefValUnique    Script Date: 8/28/99 9:32:30 AM ******/
   
   
    CREATE             proc [dbo].[bspAPCMRefValUnique]
   /***********************************************************
   * CREATED: kb 1/23/00
   * MODIFIED: GG 09/20/02 - #18522 ANSI nulls
   *			MV 12/22/03 - #22791 warn if same CMRef on different vendor
   *			MV 02/18/04 - #23826 - if validating off cmref seq and cmref is null, skip validation
   *			ES 03/11/04 - #23061 isnull wrap
   *			MV 02/09/09 - #132183 - tweaked varchar (XX) lengths for convert - increased batchvendor to 15
   * USAGE:
   *   validates CM Reference in APPayEdit to make sure it is not already in CM or in a batch
   *
   * INPUT PARAMETERS
   *   APCo      AP Co
   *   Mth
   *   BatchId
   *   CMCo      CM Co
   *   CMAcct    CM Account
   *   CMRef     The reference
   *   paymethod 'E' if EFT, 'C' if Check
   *
   * OUTPUT PARAMETERS
   *   @msg     Error message if invalid,
   * RETURN VALUE
   *   0 Success
   *   1 fail
   *****************************************************/
   
    (@apco bCompany, @mth bMonth, @batch bBatchID, @seq int, @cmco bCompany, @cmacct bCMAcct,
     @cmref bCMRef, @cmrefseq tinyint, @paymethod char(1), @vendorgroup bGroup, @vendor bVendor,
     @seqflag varchar(1), @vendormsg varchar(500)output,@msg varchar(500) output)
    as
   
    set nocount on
   
    declare @rcode int, @batchco bCompany, @batchseq int, @batchmth bMonth, @batchid int, @batchvendorgroup bGroup,
   	@batchvendor bVendor
   
    select @rcode = 0, @vendormsg = ''
    if @seqflag is null 
   	begin
   	select @seqflag = 'N'
   	end
   
    if @apco is null
    	begin
    	select @msg = 'Missing AP Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @cmco is null
    	begin
    	select @msg = 'Missing CM Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @cmref is null and @seqflag='N'	
     	begin 	
     	select @msg = 'Missing CM Reference!', @rcode = 1
    	goto bspexit
     	end
    
    if @cmref is null and @seqflag='Y'
   	begin
   	goto bspexit
     	end
   
    if exists(select * from bCMDT where CMCo = @cmco and CMAcct= @cmacct and CMRef = @cmref
       and ((CMRefSeq = @cmrefseq and @paymethod = 'C') or (CMRefSeq is null and @paymethod = 'E')))	-- #18522
           begin
           select @msg = 'CM Reference already exists in CM', @rcode = 1
           goto bspexit
           end
   
   select @batchco = Co, @batchmth = Mth, @batchid = BatchId, @batchseq = BatchSeq
   from bAPPB
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and
   	((CMRefSeq  = @cmrefseq and @paymethod = 'C') or (CMRefSeq is null and @paymethod = 'E')) -- #18522
       	and ((Co <> @apco) or (Mth <> @mth) or (BatchId <> @batch) or (BatchSeq <> @seq))
    if @@rowcount<> 0
       begin
       if @apco = @batchco and @batchmth = @mth and @batchid = @batch
           begin
           if @paymethod = 'C' --don't check if EFT since it is ok if there are multiple
                               --recs in this batch with the same cmref when they are eft's
               begin
               select @msg = 'CM Reference already exists in this batch on Batch Seq#' + 
                   isnull(convert(varchar(10),@batchseq), ''), @rcode = 1   --#23061
               goto bspexit
               end
           end
       else
           begin
           select @msg = 'CM Reference already exists in Company #' + isnull(convert(varchar(3),@batchco), '') + --#23061
               ' in month ' + isnull(convert(varchar(10),@batchmth,1), '')
               + ' for batch #' + isnull(convert(varchar(10),@batchid), '') + ' on sequence #' +
               isnull(convert(varchar(10),@batchseq), ''), @rcode = 1
           goto bspexit
           end
       end
   
   /* #22791 - warn if different vendor */
   select @batchco = Co, @batchmth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @batchvendorgroup=VendorGroup,
   	@batchvendor=Vendor
   from bAPPB
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and 
   	(VendorGroup <> @vendorgroup or Vendor <> @vendor) and
   	((Co <> @apco) or (Mth <> @mth) or (BatchId <> @batch) or (BatchSeq <> @seq))
    if @@rowcount<> 0
       begin
       if @apco = @batchco and @batchmth = @mth and @batchid = @batch 
           begin
   		if @paymethod = 'C' --don't check if EFT since it is ok if there are multiple
                               --recs in this batch with the same cmref when they are eft's
   			begin
               select @vendormsg = 'CM Reference already exists on vendorgroup: ' + isnull(convert(varchar(3), @batchvendorgroup), '') +	--#23061
   				' vendor: ' + isnull(convert(varchar(15), @batchvendor), '') +
   				' in this batch on Batch Seq#' + isnull(convert(varchar(10),@batchseq), '')
               goto bspexit
               end
           end
       else
           begin
           select @vendormsg = 'CM Reference already exists  on vendorgroup: ' + isnull(convert(varchar(3), @batchvendorgroup), '') +  --#23061
   			' vendor: ' + isnull(convert(varchar(15), @batchvendor), '') +
   			' in Company #' + isnull(convert(varchar(3),@batchco), '') +
               ' in month ' + isnull(convert(varchar(10),@batchmth, 1), '')  +
   			' for batch #' + isnull(convert(varchar(10),@batchid), '') + 
   			' on sequence #' + isnull(convert(varchar(10),@batchseq), '')
           goto bspexit
           end
       end
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCMRefValUnique] TO [public]
GO
