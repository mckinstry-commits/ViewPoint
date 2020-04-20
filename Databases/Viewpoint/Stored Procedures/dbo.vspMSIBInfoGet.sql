SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSIBInfoGet    Script Date: 04/06/2006 ******/
CREATE   proc [dbo].[vspMSIBInfoGet]
/*************************************
 * Created By:	GF 04/06/2006
 * Modified by:
 *
 * called from MSInvEdit to return information about the batch sequence.
 *
 * Pass:
 * Co				MS Company
 * BatchMth			MS Batch Month
 * BatchId			MS Batch Id
 * BatchSeq			MS Batch Sequence
 *
 * Returns:
 * subtotal			MS Batch Sequence invoice sub total
 * taxtotal			MS Batch Sequence invoice tax total
 * invtotal			MS Batch Sequence invoice total
 * disctotal		MS Batch Sequence invoice discount total
 * msid_exists		MS Batch Sequence detail exists flag
 *
 * Success returns:
 *	0 and Description from MSIB
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@co bCompany, @batchmth bMonth, @batchid bBatchID, @batchseq int,
 @subtotal bDollar output, @taxtotal bDollar output, @invtotal bDollar output,
 @disctotal bDollar output, @msid_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = '', @subtotal = 0, @taxtotal = 0, @invtotal = 0,
		@disctotal = 0, @msid_exists = 'N'

-- -- -- get batch seq description, check for detail, and get totals
if @batchseq is not null
	begin
	select @msg = Description
	from MSIB with (nolock) where Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
	-- -- -- check for detail in MSID
	if exists(select top 1 1 from MSID with (nolock) where Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq)
		begin
		select @msid_exists = 'Y'
		end

	-- -- -- accumulate MSTD totals
	select @subtotal = isnull(sum(b.MatlTotal),0) + isnull(sum(b.HaulTotal),0),
			@taxtotal = isnull(sum(b.TaxTotal),0),
			@disctotal = isnull(sum(b.DiscOff),0) + isnull(sum(b.TaxDisc),0)
	from MSTD b with (nolock) join MSID a with (nolock) on b.MSCo=a.Co and b.Mth=a.Mth and b.MSTrans=a.MSTrans
	where a.Co=@co and a.Mth=@batchmth and a.BatchId=@batchid and a.BatchSeq=@batchseq
   
	select @invtotal = isnull(@subtotal,0) + isnull(@taxtotal,0)

	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSIBInfoGet] TO [public]
GO
