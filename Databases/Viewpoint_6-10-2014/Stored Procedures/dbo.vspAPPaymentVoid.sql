SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPPaymentVoid]
   /***********************************************************
    * CREATED BY	: kb 9/4/6
    * MODIFIED BY	: 
    *              
    *
    * USED IN:
    *   APPayEdit
    *
    * USAGE: when setting a check as void. 
    * 
    * INPUT PARAMETERS
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if new vendor doesn't match vendor in
    *			 POHD or SLHD
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
    (@co bCompany , @mth bMonth, @batchid bBatchID, @batchseq int,
   	@cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @chktype char(1),
	@cmref bCMRef, @cmrefseq tinyint, @vendorgroup bGroup, @vendor bVendor, 
	@paiddate bDate,@msg varchar(255)output)
   as
   
   set nocount on
   
   declare @rcode int, @nextseq int

   select @rcode = 0
   
   -- get next available Seq# for Payment Batch
 Select @nextseq=isnull(max(BatchSeq),0)+1 from APPB where Co=@co and Mth = @mth
	and BatchId = @batchid

	--add new Seq# for voided entry - only needed if ReUse = 'N'
    insert APPB(Co, Mth, BatchId, BatchSeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, 
	  ChkType, VendorGroup, Vendor, PaidDate, Amount, VoidYN, ReuseYN )
	select @co, @mth, @batchid, @nextseq, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq,
	  @chktype, @vendorgroup, @vendor, @paiddate, 0, 'Y', 'N'
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPaymentVoid] TO [public]
GO
