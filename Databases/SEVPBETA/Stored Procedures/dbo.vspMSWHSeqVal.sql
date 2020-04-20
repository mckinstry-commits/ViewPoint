SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspMSWHSeqVal    Script Date: 02/28/2006 ******/
CREATE proc [dbo].[vspMSWHSeqVal]
/*************************************
 * Created By:	GF 02/28/2006 6.x
 * Modified by:	Dan So 03/21/08 - Issue 25572 - Return Basis Total
 *				Mark H 10/07/10 - Issue 141016 - Return Hauler and Surcharge totals.
 *				Mark H 08/08/11 - Issue 143917/D-01854 - Correct join that returns Hauler/Surcharge totals.
 *
 * called from MSHaulPayment for batch seq to return key description
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
 * @invtotal Batch total of MSWD records for batch seq
 * Description
 *
 * Success returns:
 *	0 and Description from MSWH
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @seq int,
 @invtotal bDollar = 0 output, @rectotal int = 0 output, @basistotal bUnits output, 
 @surchargetotal bDollar = 0 output, @haultotal bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = '', @invtotal = 0, @basistotal = 0

if @co is null or @mth is null or @batchid is null or @seq is null goto bspexit

if isnull(@seq, 0) <> 0
begin
	select @msg = InvDescription
	from MSWH with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	-- -- -- get invoice total from MSWD
	select @invtotal=isnull(sum(PayTotal),0), @rectotal = isnull(Count(BatchSeq),0),
           @basistotal = ISNULL(SUM(PayBasis),0)
	from MSWD with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	
	--Issue 141016 Break out Hauler and Surcharge Totals
	--Issue 143917/D-01854 - correct join.  Do not join on batch mth as you can pull in transactions 
	--from a previous month.
	select @surchargetotal = sum(w.PayTotal) 
	from MSWD w
	Join MSTD t on w.Co = t.MSCo /*and w.Mth = t.Mth*/ and w.TransMth = t.Mth and w.MSTrans = t.MSTrans
	and w.BatchId = t.InUseBatchId
	where w.Co = @co and w.Mth = @mth and w.BatchId = @batchid and w.BatchSeq = @seq and t.SurchargeKeyID is not null

	select @haultotal = sum(w.PayTotal) 
	from MSWD w
	Join MSTD t on w.Co = t.MSCo /*and w.Mth = t.Mth*/ and w.TransMth = t.Mth and w.MSTrans = t.MSTrans
	and w.BatchId = t.InUseBatchId
	where w.Co = @co and w.Mth = @mth and w.BatchId = @batchid and w.BatchSeq = @seq and t.SurchargeKeyID is null
end




bspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspMSWHSeqVal] TO [public]
GO
