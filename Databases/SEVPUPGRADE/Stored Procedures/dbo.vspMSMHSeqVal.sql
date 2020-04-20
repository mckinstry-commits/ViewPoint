SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSMHSeqVal    Script Date: 10/3/2006 ******/
CREATE proc [dbo].[vspMSMHSeqVal]
/*************************************
 * Created By:	 TRL 10/3/2006 6.x
 * Modified by:
 *
 * called from MSMatlPayment for batch seq to return key description
 * and invoice total.
 *
 * Pass:
 * @co		MS Company
 * @mth		Batch Month
 * @batchid	Batch Id
 * @seq		Batch Seq
 *
 *
 * Returns:
 * @invtotal Batch total of MSMT records for batch seq
 * Description
 *
 * @invtotal Batch total of MSMT record  total for batch seq
 * Description
 * Success returns:
 *	0 and Description from MSMH
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @seq int,
 @invtotal bDollar = 0 output, @rectotal int = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = '', @invtotal = 0

if @co is null or @mth is null or @batchid is null or @seq is null goto vspexit

if isnull(@seq, 0) <> 0
	begin
	select @msg = InvDescription
	from MSMH with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	-- -- -- get invoice total from MSWD
	select @invtotal=isnull(sum(TotalCost),0), @rectotal = isnull(Count(BatchSeq),0)
	from MSMT with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	end




vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSMHSeqVal] TO [public]
GO
