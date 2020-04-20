SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINMBInsertExistingTrans    Script Date: 12/18/2003 7:43:06 AM ******/
CREATE procedure [dbo].[bspINMBInsertExistingTrans]
/***********************************************************
* CREATED BY: RM 05/06/02
* MODIFIED By : DC 12/18/03 - 23061 -Check for ISNull when concatenating fields to create descriptions
*				GF 01/08/2008 - issue #124033 added notes to insert statements.
   
   
* USAGE:
* This Procedure is used by the INMOEntry Program to insert existing 
* records from INMO into INMB
   
* Checks batch info in bHQBC, and transaction info in bINMB.
* Adds entry to next available Seq# in bINMB
   
* INMB insert trigger will update InUseBatchId in bINMO
   
* INPUT PARAMETERS
     Co         INCO to pull from
     Mth        MOnth of batch
     BatchId    Batch ID to insert transaction into
     MO         MO pull
     IncludeItems  Y will pull all items also

* OUTPUT PARAMETERS
* RETURN VALUE
     0   success
     1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @mo bMO, 
@includeitems bYN, @errmsg varchar(256) output
as
set nocount on

declare @rcode int, @inuseby bVPUserName, @status tinyint, @mostatus tinyint,
		@dtsource bSource, @inusebatchid bBatchID, @seq int, @errtext varchar(256),
		@source bSource, @inusemth bMonth, @openMOib int, @moitem int, @valmsg varchar(256),
		@inuseflag tinyint

select @rcode = 0, @inuseflag = 0, @openMOib = 0

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MO Entry', 'INMB', @errtext output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
	end

if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
	goto bspexit
	end

/* all MO's can be pulled into a batch as long as it's */
/* InUseFlag is set to null and its status is not pending */
select @inusebatchid = InUseBatchId, @inusemth = InUseMth, @mostatus = Status 
from INMO where INCo=@co and MO=@mo
if @@rowcount = 0
	begin
	select @errmsg = 'The MO :' + isnull(@mo,'MISSING: @mo') + ' cannot be found.' , @rcode = 1
	goto bspexit
	end

---- Issue 13708
if @inusebatchid is not null or @inusemth is not null
	begin
    exec @rcode = bspINMBInUseValidation @co, @mth,  @mo, @inusebatchid output, @inusemth output, @valmsg output
    if @rcode <> 0
        begin
		select @errmsg = @valmsg
		goto bspexit
        end
    end

if @mostatus = 3
	begin
	select @errmsg = 'The MO :' + isnull(@mo,'') + ' status is pending.' , @rcode = 1
	goto bspexit
	end

---- get next available sequence # for this batch
select @seq = isnull(max(BatchSeq),0)+1 
from bINMB where Co = @co and Mth = @mth and BatchId = @batchid

/* add MO to batch */
/*bINMB Insert List*/
Insert into bINMB(Co, Mth, BatchId, BatchSeq, BatchTransType, MO, Description, JCCo, Job,
		OrderDate, OrderedBy, Status, OldDesc, OldJCCo, OldJob, OldOrderDate, OldOrderedBy,
		OldStatus, UniqueAttchID, Notes)
Select o.INCo, @mth, @batchid, @seq, 'C', o.MO, o.Description, o.JCCo, o.Job,
		o.OrderDate, o.OrderedBy, o.Status, o.Description, o.JCCo, o.Job, o.OrderDate, o.OrderedBy,
		o.Status, o.UniqueAttchID, o.Notes
from bINMO o where INCo=@co and MO=@mo
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to MO Entry Batch!', @rcode = 1
	goto bspexit
	end

---- update user memos
exec bspBatchUserMemoInsertExisting @co , @mth , @batchid , @seq, 'MO Entry', 0, @errmsg output

---- add MO items to batch
if @includeitems = 'Y'
	begin
	if exists(select * from INMI where INCo = @co and MO = @mo
              and (InUseMth is not null or InUseBatchId is not null))
			begin
			select @inuseflag  = 1
			end

	Insert into bINIB(Co, Mth, BatchId, BatchSeq, MOItem, BatchTransType, Loc, MatlGroup, Material,
			Description, JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, UM,
			OrderedUnits, UnitPrice, ECM, TotalPrice, TaxGroup, TaxCode, TaxAmt, RemainUnits,
			OldLoc, OldMatlGroup, OldMaterial, OldDesc, OldJCCo, OldJob, OldPhaseGroup, OldPhase,
			OldJCCType, OldGLCo, OldGLAcct, OldReqDate, OldUM, OldOrderedUnits, OldUnitPrice,
			OldECM, OldTotalPrice, OldTaxGroup, OldTaxCode, OldTaxAmt, OldRemainUnits, Notes)
	Select i.INCo, @mth, @batchid, @seq, i.MOItem, 'C', i.Loc, i.MatlGroup, i.Material,
			i.Description, i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.JCCType, i.GLCo, i.GLAcct, i.ReqDate,
			i.UM, i.OrderedUnits, i.UnitPrice, i.ECM, i.TotalPrice, i.TaxGroup, i.TaxCode, i.TaxAmt,
			i.RemainUnits, i.Loc, i.MatlGroup, i.Material, i.Description, i.JCCo, i.Job, i.PhaseGroup,
			i.Phase, i.JCCType, i.GLCo, i.GLAcct, i.ReqDate, i.UM, i.OrderedUnits, i.UnitPrice, i.ECM,
			i.TotalPrice, i.TaxGroup, i.TaxCode, i.TaxAmt, i.RemainUnits, Notes
	from INMI i where INCo=@co and MO=@mo and InUseMth is null and InUseBatchId is null
	end


---- Declare cursor on MOIB to update user memos in line items - BatchUserMemoInsertExisting
declare MOIB_cursor cursor for select Co,Mth, BatchId,BatchSeq, MOItem from bINIB
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq for update

/* open cursor */
open MOIB_cursor
/* set open cursor flag to true */
select @openMOib = 1

/* loop through all rows in this batch */
MOIB_cursor_loop:
fetch next from MOIB_cursor into @co,@mth, @batchid, @seq, @moitem
if @@fetch_status = -1 goto in_MOsting_end
if @@fetch_status <> 0 goto MOIB_cursor_loop
if @@fetch_status = 0
	begin
	exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'MO Entry Items', @moitem, @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = 'Unable to update user memo to MO Entry Batch!', @rcode = 1
		goto bspexit
		end
	goto MOIB_cursor_loop   --get the next seq
	end


in_MOsting_end:
	if @openMOib = 1
		begin
		close MOIB_cursor
		deallocate MOIB_cursor
		select @openMOib = 0
		end


bspexit:
	if @openMOib = 1
		begin
		close MOIB_cursor
		deallocate MOIB_cursor
		select @openMOib = 0
		end

	if @inuseflag  = 1
		begin
		select @moitem = min(MOItem)
		from INMI where INCo = @co and MO = @mo and (InUseMth is not null or InUseBatchId is not null)
		select @inusemth = InUseMth, @inusebatchid = InUseBatchId
		from INMI where INCo = @co and MO = @mo
		select @rcode =1, @errmsg = 'MO Item #' + convert(varchar(10),@moitem) +
                    ' could not be added because it is in use in batch id#'
                    + convert(varchar(10),@inusebatchid) + ' for ' +
                    convert(varchar(20),@inusemth)
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBInsertExistingTrans] TO [public]
GO
