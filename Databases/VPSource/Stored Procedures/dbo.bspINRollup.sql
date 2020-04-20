SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE PROCEDURE [dbo].[bspINRollup] 
/*********************************************************
*	Created:	RM 04/13/01
*	Modified:	GG 10/19/01 - Added validation, general cleanup	
*				DANF 02/14/03 - Issue #20127: Pass restricted batch default to bspHQBCInsert
*	          	DANF 12/21/04 - Issue #26577: Changed reference on DDUP
*				GF 01/08/2008 - issue #122222 @lastmth not being set.
*				GF 09/05/2010 - issue #141031 changed to use function vfDateOnly
*
*
* Purpose:  Called by IN Rollup form to summarize data in bINLD into
* one transaction per unique Location, Material, Transaction Type, and Month.
*
*	Input: 
*	@co				IN Company
*	@throughmonth 	Month to rollup through
*	@locgroup		Location Group restriction - rollup all Groups if null
*
*	Output:
*	@msg			Message - error text or rollup summary
*
*	Return Code:
*	0 = success, 1 = failure
*
**********************************************************/
(@co tinyint = null, @throughmonth smalldatetime = null, @locgroup bGroup = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @initcount int, @finalcount int, @today bDate, @lastclosedmth bMonth,
		@intrans int, @glco bCompany, @opencursor tinyint, @mth bMonth,  @loc bLoc, @matlgroup bGroup,
		@material bMatl, @transtype varchar(10), @postedunits bUnits, @postedunitcost bUnitCost,
		@postedtotalcost bDollar, @stkum bUM, @stkunits bUnits, @stkunitcost bUnitCost,
		@stktotalcost bDollar, @unitprice bUnitCost, @totalprice bDollar, @batchid bBatchID,
		@lastmth bMonth, @numrows int, @RestrictedBatchesDefault bYN

select @rcode = 0, @finalcount = 0

----#141031
set @today = dbo.vfDateOnly()	-- use convert to default 0 hrs, mins, secs

---- validate IN Company and get GL Co#
select @glco = GLCo
from bINCO where INCo = @co
if @@rowcount = 0
   	begin
	select @msg = 'Invalid IN Co#!', @rcode = 1
	goto bspexit
   	end

---- validate Through Month - must be closed in Subledgers
select @lastclosedmth = LastMthSubClsd
from bGLCO where GLCo = @glco
if @@rowcount = 0
   	begin
	select @msg = 'Inventory is assigned an invalid GL Co#!', @rcode = 1
	goto bspexit
   	end

if @lastclosedmth < @throughmonth
   	begin
	select @msg = 'Subledgers are still open, select a month equal to or older than '
   		+ substring(convert(varchar,@lastclosedmth,1),1,3) + substring(convert(varchar,@lastclosedmth,1),7,2), @rcode = 1
	goto bspexit
   	end

---- get # of rows eligible for rollup
select @initcount = count(*)
from bINDT t
join bINLM m on t.Loc = m.Loc and t.INCo = m.INCo
where t.INCo = @co and Mth <= isnull(@throughmonth,Mth) and Source <> 'IN Rollup'
and m.LocGroup = isnull(@locgroup,m.LocGroup)
if @initcount = 0 goto bspexit	-- nothing to rollup

---- create a cursor to summarize and process each Month/Location/Material/Trans Type/UM combination 
declare incursor cursor for
	select t.Mth, t.Loc, t.MatlGroup, t.Material, t.TransType, t.StkUM, sum(t.StkUnits),
		case sum(t.StkUnits) when 0 then 0 else sum(t.PostedTotalCost) / sum(t.StkUnits) end,
		sum(t.PostedTotalCost), 
		case sum(t.StkUnits) when 0 then 0 else sum(t.StkTotalCost) / sum(t.StkUnits) end,
		sum(t.StkTotalCost),
		case sum(t.StkUnits) when 0 then 0 else sum(t.TotalPrice) / sum(t.StkUnits) end,
		sum(t.TotalPrice)
from bINDT t
join bINLM m on t.Loc = m.Loc and t.INCo = m.INCo
where t.INCo = @co and Mth <= isnull(@throughmonth,t.Mth) and t.Source <> 'IN Rollup'	-- exclude rollup trans
and m.LocGroup = isnull(@locgroup,m.LocGroup)		-- retrict by Location Group in passed
group by t.Mth, t.Loc, t.MatlGroup, t.Material, t.TransType, t.StkUM

open incursor
select @opencursor = 1

rollup_loop:
fetch next from incursor into @mth, @loc, @matlgroup, @material, @transtype, @stkum,
			@stkunits, @postedunitcost, @postedtotalcost, @stkunitcost, @stktotalcost,
			@unitprice, @totalprice

if @@fetch_status <> 0 goto rollup_end

---- check for change in month, new Batch required for each month
if @lastmth is null or @lastmth <> @mth
	begin
	if @batchid is not null
		begin
		---- flag current batch as complete
		update bHQBC set Status = '5', DatePosted = @today, DateClosed = getdate()
		where Co = @co and Mth = @lastmth and BatchId = @batchid
		if @@rowcount = 0
			begin
			select @msg = 'Unable to update HQ Batch Control entry!', @rcode = 1
			goto bspexit
			end
		end

	---- Get Restricted batch default from DDUP 
	select @RestrictedBatchesDefault = isnull(RestrictedBatches,'N')
	from dbo.vDDUP with (nolock)
	where VPUserName = SUSER_SNAME()
	if @@rowcount <> 1
		begin
		select @rcode = 1, @msg = 'Missing :' + SUSER_SNAME() + ' from DDUP.'
		goto bspexit
		end

	---- create a new Batch 
	exec @batchid = bspHQBCInsert @co, @mth, 'IN Rollup', 'bINAB', @RestrictedBatchesDefault, 'N', null, null, @msg output
	if @batchid = 0 
		begin
		select @rcode = 1, @msg = 'Unable to insert HQ Batch Control entry!'
		goto bspexit
		end
	end

select @lastmth = @mth

begin transaction


---- get next Inventory Detail trans number
exec @intrans = bspHQTCNextTrans 'bINDT', @co, @mth, @msg output
if @intrans = 0 
	Begin
	select @msg = 'Unable to get next Inventory Detail Transaction'
	goto rollup_error
	End
Else
	Begin
	---- add new Inventory Detail entry for rollup
	insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate, Source,
			TransType, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost, StkUM,
   			StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice, BatchId)
	values(@co, @mth, @intrans, @loc, @matlgroup, @material, @today, @today, 'IN Rollup',
   			@transtype, @stkum, @stkunits, @postedunitcost, 'E', @postedtotalcost, @stkum,
   			@stkunits, @stkunitcost, 'E', @stktotalcost, @unitprice, 'E', @totalprice, @batchid)
	if @@rowcount <> 1
		begin
		select @msg = 'Unable to add Inventory Detail entry for rollup!'
		goto rollup_error
		end

	---- flag rolled up trans as ready for purge so delete trigger will not update OnHand and Avg Cost 
	update  bINDT set PurgeYN = 'Y'
	where INCo = @co and Mth = @mth and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	and TransType = @transtype and StkUM = @stkum and Source <> 'IN Rollup'

	select @numrows = @@rowcount

	---- remove rolled up detail
	delete bINDT 
	where INCo = @co and Mth = @mth and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	and TransType = @transtype and StkUM = @stkum and Source <> 'IN Rollup'
	if @numrows <> @@rowcount
		begin
		select @msg = 'Number of rolled up and deleted entries are not equal!'
		goto rollup_error
		end
	End


commit transaction


select @finalcount = @finalcount + 1	---- # of rolled up combinations

goto rollup_loop	---- next rollup combination


rollup_error:	---- error during rollup, rollback transaction
rollback transaction
	Begin
	select @rcode = 1
	goto bspexit
	End


rollup_end:
close incursor
deallocate incursor
select @opencursor = 0



if @batchid is not null
	begin
	---- flag final batch as complete
	update bHQBC set Status = '5', DatePosted = getdate(), DateClosed = getdate()
	where Co = @co and Mth = @mth and BatchId = @batchid
	if @@rowcount = 0
		begin
		select @msg = 'Unable to update HQ Batch Control entry!', @rcode = 1
		goto bspexit
		end
	end


bspexit:
	if @opencursor = 1
		begin
		close incursor
		deallocate incursor
   		end

	if @rcode = 0 
		Begin
		select @msg = 'Rolled up ' + convert(varchar(10),@initcount) + ' records into ' + convert(varchar(10),@finalcount) + ' records.'
		End

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINRollup] TO [public]
GO
