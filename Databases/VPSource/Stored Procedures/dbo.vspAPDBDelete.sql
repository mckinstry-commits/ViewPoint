SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBEditInit    Script Date: 8/28/99 9:34:01 AM ******/
   CREATE           proc [dbo].[vspAPDBDelete]
   
   
   /****************************************************************************
  * CREATED BY: kb 5/31/6
  * MODIFIED By : 
  * USAGE:
  * Called from the AP Payment Posting/Edit Program to delete the APDB detail recs when deleting an
  * APTB record
  *
  *  INPUT PARAMETERS
  *  @co             AP Company
  *  @mth            Payment Month
  *  @batchid        Batch Id
  *  @batchseq       Payment Batch Sequence
  *  @expmth         Transaction Expense Month
  *  @aptrans        AP Transaction #
  *
  * OUTPUT PARAMETERS
  *  @errmsg         error message
  *
  * RETURN VALUE
  *   0              success
  *   1              failure
  ****************************************************************************/
     (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
      @expmth bMonth = null, @aptrans bTrans = null, @errmsg varchar(255) output)
 
 as
 
 set nocount on
 
 declare @rcode int
 
select @rcode = 0

if @expmth is null and @aptrans is null
	begin
	delete from APDB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	end
else
	begin
	delete from APDB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	and ExpMth = @expmth and APTrans = @aptrans
	end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPDBDelete] TO [public]
GO
