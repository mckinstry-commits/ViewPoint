SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPManualCheckProcess]
/***********************************************************
* CREATED: kb 7/25/2 - issue #18112 - do manual check processing
* MODIFIED: MV 10/09/02 - #18842 - added error trapping
*			MV 03/01/04 - #18769 - pay category/changed pseudo cursor to real cursor
*			MV 07/06/04 - #25019 - return to APProcess_loop after updating bAPTB
*			MV 03/12/08 - #127347 - International addresses - removed unused declares
*
* USAGE:
* Called by AP Payment Batch update trigger to update transaction payment values.
*
* INPUT PARAMETERS
*	@apco				AP Company #
*	@mth				Batch Month
*	@batchid			Payment BatchId
*	@batchseq			Payment Batch Seq#
*
* OUTPUT PARAMETERS
*	@msg                error message
*
* RETURN VALUE
*   0                  success
*   1                  failure
*****************************************************/
   (@apco bCompany = null, @month bMonth = null, @batchid bBatchID = null,
    @batchseq int = null, @msg varchar(255) output)

as
set nocount on
    
declare @rcode int, @checknumstring bCMRef, @opencursorAPPB tinyint, @paymethod varchar(1),
	@cmref bCMRef, @cmrefseq tinyint, @chktype char(1), @checknum int,@expmth bMonth, @aptrans bTrans,
	@retainage bDollar, @retpaytype tinyint, @prevpaid bDollar, @batchprevpaid bDollar,
	@prevdisc bDollar, @batchprevdisc bDollar, @balance bDollar, @batchbalance bDollar,
	@disctaken bDollar, @otherbalance bDollar, @jcco bCompany, @job bJob, @opencursor int

select @opencursor = 0

-- get Retainage pay type from AP Company
select @retpaytype = RetPayType
from dbo.bAPCO (nolock)
where APCo = @apco
if @@rowcount = 0 
	begin
	select @msg = 'Invalid AP Company #', @rcode = 1
	goto bspexit
	end
    
    
declare bcAPProcess cursor LOCAL FAST_FORWARD for
select ExpMth, APTrans
from dbo.bAPTB 
where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
    
open bcAPProcess
select @opencursor = 1
    
APProcess_loop:
	fetch next from bcAPProcess into @expmth, @aptrans
	if @@fetch_status <> 0 goto APProcess_end
    
    -- get balance from AP Trans Detail
    select @balance = isnull((select sum(Amount)
								from bAPTD (nolock)
								where APCo = @apco and Mth = @expmth and APTrans = @aptrans
									and Status <3) ,0)
    
    -- get balance from Payment batch trans detail
    select @batchbalance = isnull((select sum(Amount)
									from bAPDB (nolock)
									where Co = @apco and Mth = @month and BatchId = @batchid
										and BatchSeq = @batchseq and ExpMth = @expmth and APTrans = @aptrans),0)
    -- calculate current balance
    select @balance = @balance - @batchbalance
    
    -- get retainage from AP Trans Detail
    select @retainage = sum(d.Amount)
    from bAPTD d (nolock)
    where d.APCo = @apco and d.Mth = @expmth and d.APTrans = @aptrans and d.Status = 2
    	and ((d.PayCategory is null and d.PayType = @retpaytype)
    				 or (d.PayCategory is not null and d.PayType = (select c.RetPayType from bAPPC c (nolock)
    						where c.APCo=@apco and c.PayCategory=d.PayCategory)))
              /*and PayType = @retpaytype and Status = 2*/
    
    -- get previous paid and discounts taken from AP Trans Detail
    select @prevpaid = sum(Amount) - sum(DiscTaken), @prevdisc = sum(DiscTaken)
    from bAPTD (nolock)
    where APCo = @apco and Mth = @expmth and APTrans = @aptrans and Status > 2
    
    -- get previous discounts taken from Payment batch detail
	select @batchprevdisc = sum(DiscTaken), @batchprevpaid = sum(Amount) - sum(DiscTaken)
    from bAPDB (nolock)
    where Co = @apco and ExpMth = @expmth and APTrans = @aptrans and BatchId = @batchid
		and Mth = @month and BatchSeq < @batchseq
    
    -- get previous discounts taken from Payment batch detail
	select @disctaken = sum(DiscTaken)
	from bAPDB (nolock)
	where Co = @apco and ExpMth = @expmth and APTrans = @aptrans and Mth = @month
		and BatchId = @batchid and BatchSeq = @batchseq
    
    -- calculate current discounts, retainage, previous paid, and previous discounts
    select @disctaken = isnull(@disctaken,0), @retainage = isnull(@retainage,0),
		@prevpaid = isnull(@prevpaid,0) + isnull(@batchprevpaid,0),
    	@prevdisc = isnull(@prevdisc,0) + isnull(@batchprevdisc,0)
    
    -- final calculate for current balance
    select @balance = @balance - isnull(@batchprevpaid,0) - isnull(@batchprevdisc,0)
    		
    -- update Payment batch transaction totals
    update bAPTB set Retainage = @retainage, PrevPaid = @prevpaid,
		PrevDisc = @prevdisc, Balance = @balance - @retainage, DiscTaken = @disctaken
    from bAPTB
    where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
		and ExpMth = @expmth and APTrans = @aptrans
    if @@rowcount = 0	--18842
   	 	begin
   	 	select @msg = 'Unable to update Payment Batch Transaction total for manual check process.', @rcode=1
   	 	goto bspexit
    	end
    	
   	goto APProcess_loop	--#25019 
  
APProcess_end:
	if @opencursor = 1
		begin   
		close bcAPProcess
    	deallocate bcAPProcess
    	select @opencursor = 0
		end
    
bspexit: 
	if @opencursor = 1
		begin   
		close bcAPProcess
	    deallocate bcAPProcess
		end
		 
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPManualCheckProcess] TO [public]
GO
