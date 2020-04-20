SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspAPClear]
/****************************************************************************
* CREATED: kf 10/10/97
* MODIFIED: kb 12/31/98
*            GG 11/27/00 - changed datatype from bAPRef to bAPReference
*			 MV 10/18/02 - 18878 quoted identifier cleanup 
*			 MV 10/18/05 - #27757 - isnull insert to bAPCD.Remaining
*			 MV 10/27/05 - #27757 - set @aptrans to null 
*			 MV 04/19/06 - #27757 - check if trans already in batch
*
* Used to add or remove transactions from an AP Clear batch (bAPCT/bAPCD)
*
*  INPUT PARAMETERS
*   @co				AP Company
*   @mth			Batch Month 
*   @batchid		Batch Id# 
*   @expmth			AP transaction expense and batch month 
*   @aptrans		AP transaction to be added or removed from batch, if null 
*	@deleteyn		Y = delete transaction(s) from the batch, N = add trans to batch
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @expmth bMonth = null,
	 @aptrans bTrans = null, @deleteyn bYN = 'N', @msg varchar(60) output)
as
  
set nocount on
  
declare @rcode int, @seq int, @apref bAPReference, @desc bDesc, @invdate bDate, @gross bDollar,
   	@paid bDollar, @remaining bDollar
  
select @rcode=0

--	
if @aptrans = 0 select @aptrans = null

-- remove a single transaction from the AP Clear Batch
if @deleteyn = 'Y' and @aptrans is not null
   	begin
   	-- get the batch seq#
   	select @seq=BatchSeq from dbo.bAPCT
   	where Co=@co and Mth=@mth and BatchId=@batchid and APTrans=@aptrans	and ExpMth=@expmth
   	-- remove GL distributions for this seq# from the batch
   	delete from dbo.bAPCD where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   	-- remove the transaction from the batch
   	delete from dbo.bAPCT where Co=@co and Mth=@mth and BatchId=@batchid and APTrans=@aptrans and ExpMth=@expmth
   	-- all done
   	goto bspexit
   	end
   	
-- when no trans# is passed in remove all entries from the AP Clear Batch
if @deleteyn = 'Y' and @aptrans is null
   	begin
   	-- remove all GL distributions from the batch
   	delete from dbo.bAPCD where Co=@co and Mth=@mth and BatchId=@batchid
   	-- remove all transactions from the batch 
   	delete from dbo.bAPCT where Co=@co and Mth=@mth and BatchId=@batchid
   	-- all done
   	goto bspexit
   	end

-- validate transaction before adding it to the batch
if @aptrans is null goto bspexit
	
-- see if transaction already in the batch
if exists (select 1 from dbo.bAPCT (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and 
				ExpMth = @expmth and APTrans = @aptrans)
	begin
	select @msg = 'Transaction already exists in Clear Batch', @rcode=1
   	goto bspexit
	end   

-- get transaction totals
select @apref=h.APRef, @desc=h.Description, @invdate=h.InvDate, @gross=sum(l.GrossAmt),
   	@paid=(select isnull(sum(Amount),0) + isnull(sum(DiscTaken),0) from dbo.bAPTD
   			where APCo=@co and Mth=@expmth and APTrans=@aptrans and Status=3),
   	@remaining=(select isnull(sum(Amount),0) from dbo.bAPTD where APCo=@co and Mth=@expmth 
   					and APTrans=@aptrans and Status<3)
from dbo.bAPTH h
join dbo.bAPTL l on l.APCo=h.APCo and l.Mth=h.Mth and l.APTrans=h.APTrans
   	where h.APCo = @co and h.Mth = @expmth and h.APTrans=@aptrans
   	group by h.APRef, h.Description, h.InvDate
  

-- get next available batch seq#  
select @seq = isnull(max(BatchSeq),0)+1 from dbo.bAPCT where Co=@co and Mth=@mth and BatchId=@batchid

-- make sure both the transaction and its GL distributions are added to the batch
begin transaction
-- add the transaction with its totals
insert dbo.bAPCT(Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, APRef, Description, InvDate,
	Gross, Paid, Remaining)
values (@co, @mth, @batchid, @seq, @expmth, @aptrans, @apref, @desc, @invdate,
	isnull(@gross,0), isnull(@paid,0), isnull(@remaining,0))
if @@rowcount = 0
	begin
   	rollback transaction
   	select @msg = 'Transaction was not added to Cleared Transaction Batch', @rcode = 1
   	goto bspexit
   	end
-- add a GL distribution for each expense Account on the transaction with an unpaid balance
insert dbo.bAPCD(Co, Mth, BatchId, BatchSeq, GLCo, GLAcct, Remaining)
select @co, @mth, @batchid, @seq, p.GLCo, p.GLAcct, isnull(sum(d.Amount),0)
from dbo.bAPTD d
join dbo.bAPPT p on p.APCo = d.APCo and p.PayType = d.PayType
where d.APCo = @co and d.Mth = @expmth and d.APTrans = @aptrans and d.Status < 3 -- unpaid 
group by p.GLCo, p.GLAcct
order by p.GLCo, p.GLAcct
if @@rowcount=0
   	begin
   	rollback transaction
   	select @msg = 'Problem with GL distributions, AP transaction was not added to the batch', @rcode = 1
   	goto bspexit
   	end
   	
commit transaction
   
bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPClear] TO [public]
GO
