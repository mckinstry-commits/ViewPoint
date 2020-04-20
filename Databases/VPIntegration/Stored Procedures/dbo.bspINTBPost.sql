SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE  procedure [dbo].[bspINTBPost]
/***********************************************************************************
* CREATED BY: GR 02/23/00
* Modified By: ae 5/15/00 added Description to INDT inserts and changed references from table to view.
*            : GR 5/26/00 changed references back to tables
*              GG 06/14/00  - modified for new Trans Types (Trnsfr In and Trnsfr Out)
*              MV 06/21/01  - Issue 12769 BatchUserMemoUpdate
*              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*              GWC 04/01/04 - #18616 - Re-index Attachments
*                           - added dbo. in front of stored procedure calls 
*				GF 01/28/2008 - issue #126876 - added column INTrans to INTB update after insert for custom fields.
*				GP 11/25/08 - 131227, increased description param to 60 char.
*
*
*
* USAGE:
* Called from IN Batch Processing form to post a validated
* batch of IN Transfers. Update IN Materials
*
* INPUT PARAMETERS:
*   @co             IN Company
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
**************************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(100) output)
as
set nocount on

declare @rcode int, @status int, @errorstart varchar(255), @openintb int, @msg varchar(255)

declare @batchseq int, @intrans int, @fromloc bLoc, @toloc bLoc,
		@matlgroup bGroup, @material bMatl, @actdate bDate, @description bItemDesc,
		@glco bCompany, @invglacct bGLAcct, @um bUM, @units bUnits, @unitcost bUnitCost,
		@ecm bECM, @totalcost bDollar, @costmethod int, @stdcost bUnitCost, @stkunitcost bUnitCost,
		@stdecm bECM, @iecm int, @stktotalcost bUnitCost, @stkecm bECM, @intrans1 int,
		@Notes varchar(256), @uniqueattchid uniqueidentifier

select @rcode = 0, @openintb = 0

-- check for Posting Date
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

-- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'IN Trnsfr', 'INTB', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
	begin
	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
	goto bspexit
	end

-- set HQ Batch status to 4 (posting in progress)
update bHQBC
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end

--declare cursor on INTB
declare INTB_cursor cursor LOCAL FAST_FORWARD
	for select BatchSeq, FromLoc, ToLoc, MatlGroup, Material, ActDate, Description,
				UM, Units, UnitCost, ECM, TotalCost, UniqueAttchID
from bINTB
where Co = @co and Mth = @mth and BatchId = @batchid

open INTB_cursor
select @openintb = 1

INTB_cursor_loop:                 --loop through all the records

fetch next from INTB_cursor into @batchseq, @fromloc, @toloc, @matlgroup, @material, @actdate,
		@description, @um, @units, @unitcost, @ecm, @totalcost, @uniqueattchid

if @@fetch_status = -1 goto in_posting_end
if @@fetch_status <> 0 goto INTB_cursor_loop


begin transaction                   --start a transaction


---- first get inventory glacct
select @glco=GLCo, @invglacct=InvGLAcct
from INLM with (nolock) where INCo=@co and Loc=@fromloc

---- get next available Transaction # for
exec @intrans = bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
if @intrans = 0
	begin
	select @errmsg = @errorstart + ' ' + @msg, @rcode = 1
	goto bspexit
	end
   
---- add IN Inventory Detail for Transfer From Location
insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, TrnsfrLoc, ActDate, PostedDate, Source,
		TransType, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
		StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice,
		BatchId, GLCo, GLAcct, Description)
values (@co, @mth, @intrans, @fromloc, @material, @matlgroup, @toloc, @actdate, @dateposted, 'IN Trnsfr',
		'Trnsfr Out', @um, -@units, @unitcost, @ecm, -@totalcost,
		@um, -@units, @unitcost, @ecm, -@totalcost, @unitcost, @ecm, -@totalcost,
		@batchid, @glco, @invglacct, @description)
if @@rowcount=0
	begin
	select @errmsg= @errorstart + ' Unable to insert into IN Detail', @rcode=1
	goto in_posting_error
	end

---- update IN Trans# to batch table - used for User Memo updates issue #126876
update dbo.INTB set INTrans = @intrans
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

---- call bspBatchUserMemoUpdate to update user memos in bINDT
exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, 'IN Transfer', @errmsg output
if @rcode <> 0
	begin
	select @errmsg = 'Unable to update User Memo in INDT.', @rcode = 1
	goto in_posting_error
	end


---- add IN Inventroy detail for Transfer To Location
---- get next available Transaction # for INDT
exec @intrans = bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
if @intrans = 0
	begin
	select @errmsg = @errorstart + ' ' + @msg, @rcode = 1
	goto bspexit
	end

--first get inventory glacct
select @glco=GLCo, @invglacct=InvGLAcct, @costmethod=CostMethod
from INLM with (nolock) where INCo=@co and Loc=@toloc

select @stdcost=StdCost, @stdecm= StdECM
from INMT with (nolock) where INCo=@co and Loc=@toloc and MatlGroup=@matlgroup and Material=@material

select @stkunitcost=case @costmethod when 3 then @stdcost else @unitcost end
select @iecm=case @stdecm when 'E' then 1 when 'C' then 100 when 'M' then 1000 end
select @stktotalcost=case @costmethod when 3 then (@units*@stkunitcost)/@iecm else @totalcost end
select @stkecm = case @costmethod when 3 then @stdecm else @ecm end

insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, TrnsfrLoc, ActDate, PostedDate, Source,
	TransType, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
	StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice,
	BatchId, GLCo, GLAcct, Description)
values (@co, @mth, @intrans, @toloc, @material, @matlgroup, @fromloc, @actdate, @dateposted, 'IN Trnsfr',
	'Trnsfr In', @um, @units, @unitcost, @ecm, @totalcost,
	@um, @units, @stkunitcost, @stkecm, @stktotalcost, 0, 'E', 0,
	@batchid, @glco, @invglacct, @description)
if @@rowcount=0
	begin
	select @errmsg= @errorstart + ' Unable to insert into IN Detail', @rcode=1
	goto in_posting_error
	end

---- update IN Trans# to batch table - used for User Memo updates issue #126876
update dbo.INTB set INTrans = @intrans
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

---- call bspBatchUserMemoUpdate to update user memos in bINDT before deleting the batch record
exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, 'IN Transfer', @errmsg output
if @rcode <> 0
	begin
	select @errmsg = 'Unable to update User Memo in INDT.', @rcode = 1
	goto in_posting_error
	end

---- IN Materials OnHand units and Average Unit Cost updates are done in INDT insert trigger

---- remove current Transaction from batch
delete bINTB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	select @errmsg = @errorstart + ' Unable to remove IN Transfer Batch.', @rcode = 1
	goto in_posting_error
	end


commit transaction


---- Refresh indexes for this transaction if attachments exist
if @uniqueattchid is not null
	begin
	exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
	end


goto INTB_cursor_loop



in_posting_error:
	rollback transaction
	goto bspexit

in_posting_end:
	if @openintb=1
		begin
		close INTB_cursor
		deallocate INTB_cursor
		select @openintb = 0
		end

-- GL update
exec @rcode=bspINTBPostGL @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

-- make sure all GL Distributions have been processed
if exists(select * from bINTG with (nolock) where INCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
	goto bspexit
	end

-- make sure all INAB entries have been processed
if exists(select * from bINTB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all Transfer entries were processed - unable to close the batch!', @rcode = 1
	goto bspexit
	end
 
-- set interface levels note string
select @Notes=Notes from bHQBC
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
	'GL Adjustment Interface Level set at: ' + convert(char(1), a.GLAdjInterfaceLvl) + char(13) + char(10) +
	'GL Transfer Interface Level set at: ' + convert(char(1), a.GLTrnsfrInterfaceLvl) + char(13) + char(10) +
	'GL Production Interface Level set at: ' + convert(char(1), a.GLProdInterfaceLvl) + char(13) + char(10) +
	'GL MO Interface Level set at: ' + convert(char(1), a.GLMOInterfaceLvl) + char(13) + char(10) +
	'JC MO Interface Level set at: ' + convert(char(1), a.JCMOInterfaceLvl) + char(13) + char(10)
from bINCO a where INCo=@co

-- delete HQ Close Control entries
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

-- set HQ Batch status to 5 (posted)
update bHQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end




bspexit:
	if @openintb=1
		begin
		close INTB_cursor
		deallocate INTB_cursor
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINTBPost] TO [public]
GO
