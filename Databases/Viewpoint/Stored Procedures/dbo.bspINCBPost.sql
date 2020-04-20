SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************/
CREATE    procedure [dbo].[bspINCBPost]
/************************************************************************
* Created By: GG 04/11/02
* Modified By:	GWC 04/01/2004 - #18616 - Re-index Attachments
*                            - added dbo. in front of stored procedure calls
*				DANSO 05/19/2008 - issue #30647 changed to use INCB.ECM for INDT.PostedECM
*				GP 05/25/2009 - Issue 133436 Removed HQAT code
*
*
* Posts a validated batch of MO Confirmation entries.
* Updates:
*	MO Items		Updates confirmed and remaining units
*	IN Detail		Add/change/delete transaction for material removed from stock
*	IN Material		Updates allocated units, on hand updated from bINDT trigger
*	JC Detail		Adds detail for actuals, committed if flagged for detail
*	JC Cost by Pd	Committed if not flagged for detail, actuals updated from bJCCD trigger
*
* Input:
*   @co             IN Company
*   @mth            Batch month
*   @batchid        Batch ID
*   @dateposted     Posting Date
*
* Output:
*	@errmsg			Error message
*
* Return:
*	@rcode			0 = success, 1 = error
*
************************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @dateposted bDate = null, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @status tinyint, @errorstart varchar(60), @seq int, @transtype char(1),
		@intrans bTrans, @mo bMO, @moitem bItem, @loc bLoc, @matlgroup bGroup, @material bMatl,
		@um bUM, @ecm varchar(1)/*Issue 30647*/, @confirmunits bUnits, @remainunits bUnits, @stkum bUM, @oldmo bMO, @oldmoitem bItem,
		@oldloc bLoc, @oldmatlgroup bGroup, @oldmaterial bMatl, @oldum bUM, @oldconfirmunits bUnits,
		@oldremainunits bUnits, @oldstkum bUM, @umconv bUnitCost, @guid uniqueIdentifier, @Notes varchar(256),
		@INCBopencursor tinyint

select @rcode = 0

-- check for date posted 
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end
   
-- validate HQ Batch 
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MO Confirm', 'INCB', @errmsg output, @status output
if @rcode <> 0
	begin
	select @rcode = 1
	goto bspexit
	end
if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress 
	begin
	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
	goto bspexit
	end

-- set HQ Batch status to 4 (posting in progress) 
update dbo.HQBC
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end



-- create a cursor on IN Confirmation Batch
declare bcINCB cursor LOCAL FAST_FORWARD
for select BatchSeq, BatchTransType, INTrans, MO, MOItem, Loc, MatlGroup,
		Material, UM,ECM, /*Issue 30647*/ ConfirmUnits, RemainUnits, StkUM, OldMO, OldMOItem,
		OldLoc, OldMatlGroup, OldMaterial, OldUM, OldConfirmUnits, OldRemainUnits, OldStkUM,
		UniqueAttchID
from dbo.INCB
where Co = @co and Mth = @mth and BatchId = @batchid

open bcINCB
select @INCBopencursor = 1      -- set open cursor flag

-- loop through all entries in the batch
INCB_loop:

fetch next from bcINCB into @seq, @transtype, @intrans, @mo, @moitem, @loc,@matlgroup,
		@material, @um,@ecm, @confirmunits, @remainunits, @stkum, @oldmo,@oldmoitem,
		@oldloc, @oldmatlgroup, @oldmaterial,@oldum, @oldconfirmunits,@oldremainunits,
		@oldstkum, @guid

if @@fetch_status <> 0 goto INCB_end

begin transaction
   
if @transtype = 'A'	       -- add IN Detail
	begin
	-- get next available transaction # 
	exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
	if @intrans = 0 goto INCB_posting_error

	-- add IN Detail entry
	insert dbo.INDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate,
			Source, TransType, MO, MOItem, JCCo, Job, PhaseGroup, Phase, JCCType, 
			GLCo, GLAcct, Description, PostedUM, PostedUnits, PostedUnitCost, PostECM,
			PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
			PECM, TotalPrice, BatchId, UniqueAttchID)
	select b.Co, b.Mth, @intrans, b.Loc, b.MatlGroup, b.Material, b.ConfirmDate, @dateposted,
			'IN MO', 'JC Sale', b.MO, b.MOItem, i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.JCCType,
			i.GLCo, i.GLAcct, b.Description, b.UM, -(b.ConfirmUnits), 
			case when b.ConfirmUnits <> 0 then (b.StkTotalCost/b.ConfirmUnits) else 0 end,
			b.ECM,/*Issue 30647*/ --'E',
			-(b.StkTotalCost), b.StkUM, -(b.StkUnits), b.StkUnitCost, b.StkECM, -(b.StkTotalCost),b.UnitPrice, 
			b.ECM, -(b.ConfirmTotal), b.BatchId, b.UniqueAttchID
	from dbo.INCB b with (nolock)
	join dbo.INMI i with (nolock) on b.Co = i.INCo and b.MO = i.MO and b.MOItem = i.MOItem
	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - unable to add IN Detail transaction!'
		goto INCB_posting_error
		end

	-- update IN Trans# to batch and distribution tables - used for User Memo updates
	update dbo.INCB set INTrans = @intrans where Co = @co and Mth = @mth and BatchId = @batchid
	and BatchSeq = @seq
	update dbo.INCG set INTrans = @intrans where INCo = @co and Mth = @mth and BatchId = @batchid
	and BatchSeq = @seq
	end
   
if @transtype = 'C'	   -- update
	begin
	-- update IN Detail 
	update dbo.INDT set Loc = b.Loc, MatlGroup = b.MatlGroup, Material = b.Material, ActDate = b.ConfirmDate,
			PostedDate = @dateposted, MO = b.MO, MOItem = b.MOItem, JCCo = i.JCCo, Job = i.Job,
			PhaseGroup = i.PhaseGroup, Phase = i.Phase, JCCType = i.JCCType, GLCo = i.GLCo, GLAcct = i.GLAcct,
			Description = b.Description, PostedUM = b.UM, PostedUnits = -(b.ConfirmUnits),
			PostedUnitCost = case when b.ConfirmUnits <> 0 then (b.StkTotalCost/b.ConfirmUnits) else 0 end,
			PostECM = b.ECM /*'E' Issue 30647*/, PostedTotalCost = -(b.StkTotalCost), StkUM = b.StkUM, StkUnits = -(b.StkUnits),
			StkUnitCost = b.StkUnitCost, StkECM = b.StkECM, StkTotalCost = -(b.StkTotalCost),
			UnitPrice = b.UnitPrice, PECM = b.ECM, TotalPrice = -(b.ConfirmTotal), BatchId = b.BatchId,
			UniqueAttchID = b.UniqueAttchID
	from dbo.INDT t with (nolock)
	join dbo.INCB b with (nolock) on t.INCo = b.Co and t.Mth = b.Mth and t.INTrans = b.INTrans
	join dbo.INMI i with (nolock) on b.Co = i.INCo and b.MO = i.MO and b.MOItem = i.MOItem
	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - unable to update IN Detail transaction!'
		goto INCB_posting_error
		end
	end
   
if @transtype = 'D'    	-- delete
	begin
	-- remove IN Detail
	delete dbo.INDT where INCo = @co and Mth = @mth and INTrans = @intrans
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - Unable to delete IN Detail transaction!'
		goto INCB_posting_error
		end
	end
   
if @transtype in ('A','C')
	begin
	-- update MO Item with 'new' confirmation values 
	update dbo.INMI set ConfirmedUnits = ConfirmedUnits + @confirmunits,
					RemainUnits = RemainUnits + @remainunits
	where INCo = @co and MO = @mo and MOItem = @moitem
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - unable to update Material Order Item!'
		goto INCB_posting_error
		end
	-- get material u/m conversion factor 
	select @umconv = 1
	if @um <> @stkum
		begin
		select @umconv = Conversion
		from dbo.INMU with(nolock)
		where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material and UM = @um
		if @@rowcount = 0
			begin
			select @errmsg = @errorstart + ' - Material U/M not setup at IN Location!'
			goto INCB_posting_error
			end
		end
	-- update IN Material Allocations by change in Remaining Units
	update dbo.INMT set Alloc = Alloc + (@remainunits * @umconv), AuditYN = 'N'	-- no audits with system updates
	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to update IN Material allocated quantity!'
		goto INCB_posting_error
		end
	-- reset audit flag
	update dbo.INMT set AuditYN = 'Y'	
	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to reset IN Material audit flag!'
		goto INCB_posting_error
		end

	-- update user memos 
	exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'IN MO Confirm', @errmsg output
	if @rcode <> 0	goto INCB_posting_error

	end
   
if @transtype in ('C','D')
	begin
	-- back out 'old' from MO Item
	update dbo.INMI set ConfirmedUnits = ConfirmedUnits - @oldconfirmunits,
				RemainUnits = RemainUnits - @oldremainunits
	where INCo = @co and MO = @oldmo and MOItem = @oldmoitem
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - unable to update Material Order Item!'
		goto INCB_posting_error
		end
	-- get material u/m conversion factor 
	select @umconv = 1
	if @oldum <> @oldstkum
		begin
		select @umconv = Conversion
		from dbo.INMU with(nolock)
		where INCo = @co and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial and UM = @oldum
		if @@rowcount = 0
			begin
			select @errmsg = @errorstart + ' - Material U/M not setup at IN Location!'
			goto INCB_posting_error
			end
		end
	-- update IN Material Allocations by change in Remaining Units
	update dbo.INMT set Alloc = Alloc - (@oldremainunits * @umconv), AuditYN = 'N'	-- no audits with system updates
	where INCo = @co and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to update IN Material allocated quantity!'
		goto INCB_posting_error
		end
	-- reset audit flag
	update dbo.INMT set AuditYN = 'Y'	
	where INCo = @co and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to reset IN Material audit flag!'
		goto INCB_posting_error
		end
	end
    
-- delete current entry from batch
delete dbo.INCB
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
if @@rowcount <> 1
	begin
	select @errmsg = @errorstart + ' - Error removing entry from batch.'
	goto INCB_posting_error
	end

-- commit transaction
commit transaction
   
--Re-index attachments	
if @transtype in ('A','C')
	begin
	if @guid is not null
		begin
		exec @rcode = dbo.bspHQRefreshIndexes null, null, @guid
		end
	end

goto INCB_loop      -- next batch entry

INCB_posting_error:
	rollback transaction
	select @rcode = 1
	goto bspexit

INCB_end:   -- finished with batch entries
	close bcINCB
	deallocate bcINCB
	select @INCBopencursor = 0
   
   
/*** JC Update ***/ 
exec @rcode = dbo.bspINCBPostJC @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

/*** GL Update ***/
exec @rcode = dbo.bspINCBPostGL @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

-- make sure batch and distribution tables are empty
if exists(select 1 from dbo.INCB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all MO Confirmation batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end
if exists(select 1 from dbo.INCJ with(nolock) where INCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all JC Distributions were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end
if exists(select 1 from dbo.INCG with(nolock) where INCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
	goto bspexit
	end
   
-- unlock MO Header and Items that where in this batch
update dbo.INMO
set InUseMth = null, InUseBatchId = null
where INCo = @co and InUseMth = @mth and InUseBatchId = @batchid

update dbo.INMI
set InUseMth = null, InUseBatchId = null
where INCo = @co and InUseMth = @mth and InUseBatchId = @batchid

-- set interface levels note string
select @Notes=Notes from dbo.HQBC with(nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
'JC Interface Level set at: ' + convert(char(1), JCMOInterfaceLvl) + char(13) + char(10) +
'GL Interface Level set at: ' + convert(char(1), GLMOInterfaceLvl) + char(13) + char(10)
from dbo.INCO with(nolock) where INCo=@co

-- delete HQ Close Control entries
delete dbo.HQCC where Co = @co and Mth = @mth and BatchId = @batchid

-- update HQ Batch status to 5 (posted)
update dbo.HQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end



bspexit:
	if @INCBopencursor = 1
		begin
		close bcINCB
		deallocate bcINCB
		end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBPost] TO [public]
GO
