SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINABPost    Script Date: 12/5/2003 7:23:25 AM ******/
CREATE     procedure [dbo].[bspINABPost]
/***********************************************************************************
   * CREATED BY: GR  12/10/1999
   * Modified By:GG  03/02/2000 - cleanup, removed @source param, reversed sign on units
   *                              and total cost.
   *             GR  04/12/2000 - added description to INDT and updated INAG to include INTrans
   *             GG  06/14/2000 - added new IN Trans Type for expense entries
   *             MV  06/21/2001 - Issue 12769 BatchUserMemoUpdate
   *             RM  09/07/2001 - Added Source 'IN Count'
   *             RM  09/13/2001 - Removed Source 'IN Count'
   *                            - Added BatchType (@batchtype)
   *           TV/RM 02/22/2002 - Attachment Fix
   *             CMW 04/04/2002 - added bHQBC.Notes interface levels update (issue # 16692).
   *             GG  04/08/2002 - #16702 - remove parameter from bspBatchUserMemoUpdate
   *             GG  10/09/2002 - #18848 - use 'Rec Adj' TransType for Monthly Rec adjustments
   *             DC  12/05/2003 - #23061 - Check for ISNull when concatenating fields to create descriptions
   *             GWC 04/01/2004 - #18616 - Re-index Attachments
   *                            - added dbo. in front of stored procedure calls
   *			GP 11/25/08 - 131227, increased description param to 60 char.
   *			GP 05/15/09 - 133436 Removed HQAT code
   *
   * USAGE:
   * Called from IN Batch Processing form to post a validated
   * batch of IN Adjustment transactions. Update IN Materials
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
   
declare @rcode int, @status int, @openinab int, @msg varchar(255)

declare @batchseq int, @batchtranstype varchar(3), @intrans int, @loc bLoc, @matlgroup bGroup,
	@material bMatl, @actdate bDate, @description bItemDesc, @glco bCompany, @glacct bGLAcct, @um bUM,
	@units bUnits, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar,
	@keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128),
	@guid uniqueIdentifier, @Notes varchar(256)

declare @lmadjglacct bGLAcct, @category varchar(10), @loadjglacct bGLAcct, @adjglacct bGLAcct, @transtype varchar(10),@batchtype varchar(15)

select @rcode = 0, @openinab = 0

-- check for Posting Date
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

-- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'IN Adj', 'INAB', @errmsg output, @status output
if @rcode <> 0
	begin
	goto bspexit
	end
if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
	begin
	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
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
   
--declare cursor on INAB
declare INAB_cursor cursor LOCAL FAST_FORWARD
for select BatchSeq, BatchTransType, INTrans, Loc, MatlGroup, Material, ActDate, Description,
		GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost,BatchType, UniqueAttchID
from bINAB
where Co = @co and Mth = @mth and BatchId = @batchid

open INAB_cursor
select @openinab = 1

INAB_cursor_loop:                 --loop through all the records
fetch next from INAB_cursor into @batchseq, @batchtranstype, @intrans, @loc, @matlgroup,
		@material, @actdate, @description, @glco, @glacct, @um, @units, @unitcost, @ecm, 
		@totalcost,@batchtype, @guid

if @@fetch_status = -1 goto in_posting_end
if @@fetch_status <> 0 goto INAB_cursor_loop
   
if @batchtranstype in ('A','C')
	begin
	-- determine if entry is Adjustment or Expense based on posted GL Acct and material's IN Adj Inv GL Acct
	-- get IN Adj GL Account
	select @lmadjglacct = null
	select @lmadjglacct = AdjGLAcct
	from bINLM with (nolock) where INCo = @co and Loc = @loc
	if @@rowcount = 0
		begin
		select @errmsg = ' Invalid IN Location.', @rcode = 1
		goto bspexit
		end

	--get material category
	select @category = Category
	from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		begin
		select @errmsg = ' Invalid Material.', @rcode = 1
		goto bspexit
		end
	--check for override IN Adj GL Account
	select @loadjglacct = null
	select @loadjglacct = AdjGLAcct
	from bINLO with (nolock) 
	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Category = @category

	select @adjglacct = isnull(@loadjglacct,@lmadjglacct)
	if @adjglacct is null
		begin
		select @errmsg = ' Missing IN Adjustment GL Account.', @rcode = 1
		goto bspexit
		end

	-- if posted GL Acct matches Adj GL Acct then trans type is Adj, else Expense
	if @glacct = @adjglacct select @transtype = 'Adj' else select @transtype = 'Exp'

	-- #18848 - if entry was created from Monthly Reconcilation, use a unique trans type
	if @description like 'Mthly Recon Adjustment%' select @transtype = 'Rec Adj'
	end


begin transaction                   --start a transaction


if @batchtranstype = 'A'            --new transaction
	begin
	-- get next available Transaction # for INDT
	exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
	if @intrans = 0
		begin
		select @errmsg = @msg, @rcode = 1
		goto in_posting_error
		end

	--update INAG IN trans number for GLDT updates
	update bINAG set INTrans=@intrans where INCo=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq

	-- add IN Inventory Detail - units and total cost updated as posted
	insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate, Source,
		TransType, GLCo, GLAcct, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
		StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice,
		BatchId, Description, UniqueAttchID)
	values (@co, @mth, @intrans, @loc, @matlgroup, @material, @actdate, @dateposted, 'IN Adj',
		@transtype, @glco, @glacct, @um, @units, @unitcost, @ecm, @totalcost,
		@um, @units, @unitcost, @ecm, @totalcost, 0, 'E', 0,
		@batchid, @description, @guid)

	-- IN Materials OnHand, Average Cost, and Last Cost updates are done in INDT insert trigger
	end

/* update INTrans in batch table bINAB for BatchUserMemoUpdate */
update bINAB set INTrans=@intrans
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq

if @batchtranstype = 'C'      --updating existing transaction
	begin
	update bINDT
		set Loc = @loc, Material = @material, MatlGroup = @matlgroup, ActDate = @actdate,
		PostedDate = @dateposted, TransType = @transtype, PostedUM = @um, PostedUnits = @units,
		PostedUnitCost = @unitcost, PostECM = @ecm, PostedTotalCost = @totalcost,
		StkUM = @um, StkUnits = @units, StkUnitCost = @unitcost, StkECM = @ecm,
		StkTotalCost = @totalcost, BatchId = @batchid, GLCo = @glco, GLAcct = @glacct,
		Description = @description, UniqueAttchID = @guid
	where INCo = @co and Mth = @mth and INTrans = @intrans
	if @@rowcount=0
		begin
		select @errmsg= ' Unable to update IN Detail.', @rcode=1
		goto in_posting_error
		end

	-- IN Materials OnHand and Average Cost updates are done in INDT update trigger
	end

if @batchtranstype = 'D'
	begin
	-- remove IN Detail Entry
	delete bINDT where INCo = @co and Mth = @mth and INTrans = @intrans
	if @@rowcount = 0
		begin
		select @errmsg = ' Unable to remove IN Detail Entry.', @rcode = 1
		goto in_posting_error
		end

	end

/* call bspBatchUserMemoUpdate to update user memos in bINDT before deleting the batch record */
if @batchtranstype in ('A','C')
	begin
	exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, 'IN Adjustments', @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = 'Unable to update User Memo in INDT.', @rcode = 1
		goto in_posting_error
		end
	end

-- remove current Transaction from batch
delete bINAB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	select @errmsg = ' Unable to remove IN Adjustment Batch.', @rcode = 1
	goto in_posting_error
	end

--If BatchType  is IN Count, then update Last Count Date in INLM
if @batchtype = 'IN Count'
	begin
	--Update Last Count Date
	update bINMT set LastCntDate = @actdate
	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	end


commit transaction

--Re-index attachments	
if @batchtranstype in ('A','C')
	begin
	if @guid is not null
		begin
		exec @rcode = dbo.bspHQRefreshIndexes null, null, @guid
		end
	end

goto INAB_cursor_loop               --get the next seq

in_posting_error:
	rollback transaction
	goto bspexit

in_posting_end:
	if @openinab = 1
		begin
		close INAB_cursor
		deallocate INAB_cursor
		select @openinab = 0
		end

-- GL update
exec @rcode = dbo.bspINABPostGL @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

-- make sure all GL Distributions have been processed
if exists(select * from bINAG where INCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
	goto bspexit
	end

-- make sure all INAB entries have been processed
if exists(select * from bINAB where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all Adjustment Batch entries were processed - unable to close the batch!', @rcode = 1
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
	if @openinab=1
		begin
		close INAB_cursor
		deallocate INAB_cursor
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINABPost] TO [public]
GO
