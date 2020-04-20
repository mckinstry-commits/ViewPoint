
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[bspPORBPost]
/************************************************************************
* Created: ??
* Modified by: kb 12/9/98
*              GG 11/04/99 - Cleanup
*              Dan F 02/04/2000 - Add Reciever Number
*              Dan F 09/5/2000 - Add Notes.
*              Dan F 05/30/01 - Add check for Inserted record.
*              MV    06/15/01 - Issue 12769 - BatchUserMemoUpdate
*              TV/RM Attachment Fix
*              CMW 03/15/02 - issue # 16503 JCCP column name changes.
*              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*              DANF 05/01/02 - Added Interface levels from PORH for Initializing Receipts.
*			  GF - 02/03/2003 - issue #20058 need to set INMT.AuditYN back to INCO.AuditMatl
*			  RBT 08/12/03 - Issue #22104, copy InvdFlag to PORD when posting batch.
*			  RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*		 	  RT 12/04/03 - #18616, Reindex attachments after posting A or C records.
*			  MV 03/16/04 - #24044 use RecDate from bPORA to update ActualDate in bJCCD
*			  DC 10/21/08 - #128052 Remove Committed Cost flag in POCO
*			  GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			DC 05/18/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
*			DC 12/10/09 - #122288 - Store Tax Rate in POIT
*			MH 12/07/10 - #131640 - Post some info back to SM
*			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*			GF 08/22/2011 TK-07879 PO ITEM LINE
*			JVH 9/1/11 - TK-08138 Capture SM GL distributions
*			JB 12/10/12 - Fix to support SM PO receiving
*			EricV 05/14/13 - TFS-50101 Pass the GL Interface Level to the vspSMWorkCompletedPost procedure.
*			
* Posts a validated batch of PO Receipt entries.  Updates
* PO Receipt Detail, PO Items, JC Detail and Cost by Period,
* and IN Location Materials.
*
* Inputs:
*   @co             PO Company
*   @mth            Batch month
*   @batchid        Batch ID
*   @dateposted     Posting Date
*   @source         Source - 'PO Change' or 'PM Intface'
*
* returns 1 and message if error
************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
 @source bSource, @errmsg varchar(255) output)

 as
 set nocount on
   
declare @rcode int, @status tinyint, @errorstart varchar(60),
		@PORBopencursor tinyint, @PORAopencursor tinyint, @PORIopencursor tinyint,
		@vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup, @material bMatl,
		@keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128),
		@guid uniqueIdentifier, @Notes varchar(256), @GLRecExpInterfacelvl tinyint

-- PORB declares
declare @seq int, @transtype char(1), @potrans bTrans, @po varchar(30), @poitem bItem, @recvddate bDate,
		@recvdby char(10),  @description bDesc, @recvdunits bUnits, @recvdcost bDollar, @bounits bUnits,
		@bocost bDollar, @oldpo varchar(30), @oldpoitem bItem, @oldrecvddate bDate, @oldrecvdby varchar(10),
		@olddesc bDesc, @oldrecvdunits bUnits, @oldrecvdcost bDollar, @oldbounits bUnits, @oldbocost bDollar,
		@Receiver# varchar(20), @OldReceiver# varchar(20), @InvdFlag bYN, @OldInvdFlag bYN

-- PORA declares
declare @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @oldnew tinyint,
		@um bUM, @jcum bUM, @rniunits bUnits, @rnicost bDollar, @cmtdunits bUnits, @cmtdcost bDollar, @jctrans bTrans,
		@totalcmtdtax bDollar, @remcmtdtax bDollar,
		----TK-07879
		@POItemLine INT, @OldPOItemLine INT, @TaxGroup bGroup, @TaxType TINYINT, @TaxCode bTaxCode
   
-- PORI delcares
declare @inco bCompany, @loc bLoc, @onorder bUnits

select @rcode = 0


	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = @source, @TableName = 'PORB', @DatePosted = @dateposted, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode

   
-- create a cursor on PO Receipts Batch
declare bcPORB cursor for
select BatchSeq, BatchTransType, POTrans, PO, POItem, RecvdDate, RecvdBy, Description,
		RecvdUnits, RecvdCost, BOUnits, BOCost, OldPO, OldPOItem, OldRecvdDate, OldRecvdBy,
		OldDesc, OldRecvdUnits, OldRecvdCost, OldBOUnits, OldBOCost, Receiver#, OldReceiver#,
		InvdFlag, OldInvdFlag, UniqueAttchID,
		----TK-07879
		POItemLine, OldPOItemLine
from dbo.bPORB with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid

open bcPORB
select @PORBopencursor = 1      -- set open cursor flag

-- loop through all entries in the batch
PORB_loop:
fetch next from bcPORB into @seq, @transtype, @potrans, @po, @poitem,
		@recvddate, @recvdby, @description, @recvdunits, @recvdcost,
		@bounits, @bocost, @oldpo, @oldpoitem, @oldrecvddate, @oldrecvdby,
		@olddesc, @oldrecvdunits, @oldrecvdcost, @oldbounits, @oldbocost, @Receiver#,
		@OldReceiver#, @InvdFlag, @OldInvdFlag, @guid,
		@POItemLine, @OldPOItemLine
   
	if @@fetch_status <> 0 goto PORB_end
   
	select @errorstart = 'PO Change Batch Seq# ' + convert(varchar(6),@seq)
   
	begin transaction
   
if @transtype = 'A'	       -- add PO Receipt
	BEGIN
	-- get next available transaction # for PORD
	exec @potrans = bspHQTCNextTrans 'bPORD', @co, @mth, @errmsg output
	if @potrans = 0
		begin
		select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
		goto PORB_posting_error
		end

	-- add PO Receipts Detail
	insert dbo.bPORD (POCo, Mth, POTrans, PO, POItem, RecvdDate, RecvdBy, Description, RecvdUnits, RecvdCost,
			BOUnits, BOCost, PostedDate, BatchId, InUseBatchId, Purge, Receiver#, InvdFlag,
			Notes, UniqueAttchID,
			----TK-07879
			POItemLine)
	select @co, @mth, @potrans, @po, @poitem, @recvddate, @recvdby, @description, @recvdunits, @recvdcost,
			@bounits, @bocost, @dateposted, @batchid, null, 'N', @Receiver#, @InvdFlag, --issue 22104
			Notes, @guid,
			----TK-07879
			@POItemLine
	from bPORB with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - unable to insert record', @rcode = 1
		goto PORB_posting_error
		end

	-- update PO Trans# to distribution tables
	update bPORG set POTrans = @potrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	update bPORJ set POTrans = @potrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	update bPORE set POTrans = @potrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	update bPORN set POTrans = @potrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	--update potrans# in the batch record for BatchUserMemoUpdate
	update bPORB set POTrans = @potrans
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	
	UPDATE dbo.vGLEntryBatch
	SET Trans = @potrans
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq

	END
   
   
if @transtype = 'C'	   -- update
	BEGIN
	update dbo.bPORD
			SET PO = @po, POItem = @poitem, RecvdDate = @recvddate,RecvdBy = @recvdby,
				Description = @description, RecvdUnits = @recvdunits, RecvdCost = @recvdcost,
				BOUnits = @bounits, BOCost = @bocost, PostedDate = @dateposted,
				BatchId = @batchid, InUseBatchId = null, Purge = 'N', Receiver# = @Receiver#,
				InvdFlag = @InvdFlag, UniqueAttchID = @guid,
				----TK-07879
				POItemLine = @POItemLine
	where POCo = @co and Mth = @mth and POTrans = @potrans
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + '- Unable to update PO Receipt Detail!', @rcode = 1
		goto PORB_posting_error
		end

	--update notes seperately
	update bPORD set Notes = b.Notes
	from dbo.bPORD d
	join dbo.bPORB b on d.POCo=b.Co and b.Mth=d.Mth and b.POTrans=d.POTrans
	where b.Co=@co and b.Mth=@mth and b.POTrans = @potrans
	END
   
if @transtype = 'D'    	-- delete
	BEGIN
	-- remove PO Receipt Detail
	delete dbo.bPORD where POCo = @co and Mth = @mth and POTrans = @potrans
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - Unable to delete PO Receipt Detail transaction!', @rcode = 1
		goto PORB_posting_error
		end
	END
   
   
if @transtype in ('C','D')      -- back out 'old' values from PO Item
	BEGIN
	----TK-07879
	UPDATE dbo.vPOItemLine
			SET RecvdUnits = CASE item.UM WHEN 'LS' THEN 0 ELSE (line.RecvdUnits - @oldrecvdunits) END,
				RecvdCost  = CASE item.UM WHEN 'LS' THEN (line.RecvdCost - @oldrecvdcost) ELSE 0 END,
				BOUnits	   = CASE item.UM WHEN 'LS' THEN 0 ELSE (line.BOUnits - @oldbounits) END,
				BOCost	   = CASE item.UM WHEN 'LS' THEN (line.BOCost - @oldbocost) ELSE 0 END,
				-- Total and Remaining values updated by trigger
				PostedDate = @dateposted
	FROM dbo.vPOItemLine line
	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
	WHERE line.POCo = @co AND line.PO = @oldpo
			AND line.POItem = @oldpoitem
			AND line.POItemLine = @OldPOItemLine	
	--update bPOIT
	--set RecvdUnits = case UM WHEN 'LS' then 0 else (RecvdUnits - @oldrecvdunits) end,
	--	RecvdCost = case UM WHEN 'LS' then (RecvdCost - @oldrecvdcost) else 0 end,
	--	BOUnits = case UM WHEN 'LS' then 0 else (BOUnits - @oldbounits) end,
	--	BOCost = case UM WHEN 'LS' then (BOCost - @oldbocost) else 0 end,
	--	-- Total and Remaining values updated by trigger
	--	PostedDate = @dateposted
	--where POCo = @co and PO = @oldpo and POItem = @oldpoitem
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to update (old) PO Item Line values!', @rcode = 1
		goto PORB_posting_error
		end
	END
   
if @transtype in ('A','C')      -- update PO Item with 'new' values
	BEGIN
	----TK-07879
	UPDATE dbo.vPOItemLine
			SET RecvdUnits = CASE item.UM WHEN 'LS' THEN 0 ELSE (line.RecvdUnits + @recvdunits) END,
				RecvdCost  = CASE item.UM WHEN 'LS' THEN (line.RecvdCost + @recvdcost) ELSE 0 END,
				BOUnits	   = CASE item.UM WHEN 'LS' THEN 0 ELSE (line.BOUnits + @bounits) END,
				BOCost	   = CASE item.UM WHEN 'LS' THEN (line.BOCost + @bocost) ELSE 0 END,
				-- Total and Remaining values updated by trigger
				PostedDate = @dateposted
	FROM dbo.vPOItemLine line
	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
	WHERE line.POCo = @co AND line.PO = @po
			AND line.POItem = @poitem
			AND line.POItemLine = @POItemLine	
	--update bPOIT
	--set RecvdUnits = case UM when 'LS' then 0 else (RecvdUnits + @recvdunits) end,
	--	RecvdCost = case UM when 'LS' then (RecvdCost + @recvdcost) else 0 end,
	--	BOUnits = case UM when 'LS' then 0 else (BOUnits + @bounits) end,
	--	BOCost = case UM when 'LS' then (BOCost + @bocost) else 0 end,
	--	-- Total and Remaining values updated by trigger
	--	PostedDate = @dateposted
	--where POCo = @co and PO = @po and POItem = @poitem
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - Unable to update PO Item Line values!', @rcode = 1
		goto PORB_posting_error
		end
	end
   
if @transtype  <> 'D'
	begin
	/* call bspBatchUserMemoUpdate to update user memos in bPORD before deleting the batch record */
	exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'PO Receipts', @errmsg output
	if @rcode <> 0	goto PORB_posting_error
	end
		
-- delete current entry from batch
delete bPORB
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
if @@rowcount <> 1
	begin
	select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
	goto PORB_posting_error
	end
   
-- commit transaction
commit transaction
   
--issue 18616
if @transtype in ('A','C')
	begin
	if @guid is not null
		begin
		exec @rcode = bspHQRefreshIndexes null, null, @guid, null
		end
	end
   
	goto PORB_loop      -- next batch entry
   
	PORB_posting_error:
		rollback transaction
		goto bspexit
   
	PORB_end:   -- finished with PO Receipt Batch entries
		close bcPORB
		deallocate bcPORB
		select @PORBopencursor = 0
   
   
	-- create a cursor on PO Receipts JC Distribution Batch for posting
	declare bcPORA cursor for
	select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, PO, POItem, UM,
			RecvdUnits, BOUnits, JCUM, RNIUnits, RNICost, CmtdUnits, CmtdCost, RecDate, -- #24044 use RecDate from bPORA
			TotalCmtdTax, RemCmtdTax,
			----TK-07879
			POItemLine, Description, TaxGroup, TaxType, TaxCode
	from bPORA with (nolock)
	where POCo = @co and Mth = @mth and BatchId = @batchid
   
	open bcPORA
	select @PORAopencursor = 1
   
	-- process each PO JC Distribution entry
	PORA_loop:
	fetch next from bcPORA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew, @po, @poitem,
			@um, @recvdunits, @bounits, @jcum, @rniunits, @rnicost, @cmtdunits, @cmtdcost, @recvddate,	--#24044
			@totalcmtdtax, @remcmtdtax,  --DC #122288
			----TK-07879
			@POItemLine, @description, @TaxGroup, @TaxType, @TaxCode
			
	if @@fetch_status <> 0 goto PORA_end
   
	begin transaction
   
	if @cmtdunits <> 0 or @cmtdcost <> 0
		begin
		-- get Vendor info from PO Header
		select @vendorgroup = VendorGroup, @vendor = Vendor
		from bPOHD with (nolock) where POCo = @co and PO = @po
		-- get Material info from PO Item
		select @matlgroup = MatlGroup, @material = Material
		from bPOIT with (nolock) where POCo = @co and PO = @po and POItem = @poitem

		-- get next available transaction # for JCCD
		exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
		if @jctrans = 0
			begin
			select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
			goto PORA_posting_error
			end

		-- add JC Cost Detail
		insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			JCTransType, Source, Description, BatchId, PostedUM, PostTotCmUnits, PostRemCmUnits,
			UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo,
			PO, POItem, MatlGroup, Material,
			TotalCmtdTax, RemCmtdTax,  --DC #122288
			----TK-07879
			POItemLine, TaxGroup, TaxType, TaxCode)
		values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @recvddate,
			'PO', @source, @description, @batchid, @um, (@recvdunits + @bounits), (@recvdunits + @bounits),
			@jcum, @cmtdunits, @cmtdcost, @cmtdunits, @cmtdcost, @vendorgroup, @vendor, @co,
			@po, @poitem, @matlgroup, @material,
			@totalcmtdtax, @remcmtdtax,  --DC #122288
			----TK-07879
			@POItemLine, @TaxGroup, @TaxType, @TaxCode)
		if @@rowcount <> 1
			begin
			select @errmsg = @errorstart + ' - Error inserting JC Cost detail.', @rcode = 1
			goto PORA_posting_error
			end
		end
   
	-- update JC Cost by Period with change to Received N/Invoiced
	if @rniunits <> 0 or @rnicost <> 0
		begin
		update bJCCP
		set RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost
		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
		and Phase = @phase and CostType = @jcctype
		if @@rowcount = 0
			begin
			insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RecvdNotInvcdUnits, RecvdNotInvcdCost)
			values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @rniunits, @rnicost)
			if @@rowcount <> 1
				begin
				select @errmsg = @errorstart + ' - Error inserting JC Cost by period.', @rcode = 1
				goto PORA_posting_error
				end
			end
		end
   
	-- delete current PO JC Distribution entry
	delete bPORA
	where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
		and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
		and BatchSeq = @seq and OldNew = @oldnew
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
		goto PORA_posting_error
		end
   
	commit transaction
	goto PORA_loop      -- next PO Job distribution entry
   
	PORA_posting_error:
		rollback transaction
		goto bspexit
   
	PORA_end:
		close bcPORA
		deallocate bcPORA
		select @PORAopencursor = 0
  
  
---- create a cursor on PO Receipts IN Distribution Batch for posting
declare bcPORI cursor FOR select INCo, Loc, MatlGroup, Material, BatchSeq, OldNew, RecvdNInvcd, OnOrder
from dbo.bPORI with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid

open bcPORI
select @PORIopencursor = 1

-- process each PO IN Distribution entry
PORI_loop:
fetch next from bcPORI into @inco, @loc, @matlgroup, @material, @seq, @oldnew, @recvdunits, @onorder

if @@fetch_status <> 0 goto PORI_end

select @errorstart = 'PO IN Distribution Seq# ' + convert(varchar(6),@seq)

begin transaction

if @recvdunits <> 0 or @onorder <> 0
	BEGIN
	UPDATE dbo.bINMT
		set RecvdNInvcd = RecvdNInvcd + @recvdunits,
			OnOrder = OnOrder + @onorder,
			AuditYN = 'N'     -- do not trigger HQMA update
	WHERE INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		begin
		select @errmsg = @errorstart + ' - Unable to update values for IN Material!', @rcode = 1
		goto PORI_posting_error
		end
	-- reset audit flag in INMT
	UPDATE bINMT SET AuditYN = 'Y'
	FROM dbo.bINMT a where a.INCo=@inco and a.Loc=@loc and a.MatlGroup=@matlgroup and a.Material=@material
	END

-- delete current PO IN Distribution entry
delete bPORI
where POCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc
	and MatlGroup = @matlgroup and Material = @material and BatchSeq = @seq and OldNew = @oldnew
if @@rowcount <> 1
	begin
	select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
	goto PORI_posting_error
	end

commit transaction
goto PORI_loop      -- next PO IN distribution entry

PORI_posting_error:
	rollback transaction
	goto bspexit
   
	PORI_end:
		close bcPORI
		deallocate bcPORI
		select @PORIopencursor = 0
   
	-- make sure batch tables are empty
	if exists(select * from bPORB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
		begin
     	select @errmsg = 'Not all PO Receipt batch entries were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
     if exists(select * from bPORA with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @errmsg = 'Not all JC Distributions were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
     if exists(select * from bPORI with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @errmsg = 'Not all IN Distributions were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
   
	exec @rcode=bspPORBExpPostJC @co, @mth, @batchid, @dateposted, @errmsg output
	if @rcode <> 0 goto bspexit
   
	-- make sure all JC Distributions have been processed
	if exists(select * from bPORJ with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all updates to JC were posted - unable to close the batch!', @rcode = 1
		goto bspexit
		end
   
	exec @rcode=bspPORBExpPostGL @co, @mth, @batchid, @dateposted, @errmsg output
	if @rcode <> 0 goto bspexit
   
	-- make sure all GL Distributions have been processed
	if exists(select * from bPORG with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
		goto bspexit
		end

	DECLARE @PORDGLEntryToProcess TABLE (POCo bCompany, Mth bMonth, POTrans bTrans, GLEntryID bigint, PORDGLID bigint NULL)

	INSERT @PORDGLEntryToProcess
	SELECT Co, Mth, Trans, GLEntryID, NULL AS PORDGLID
	FROM dbo.vGLEntryBatch
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid

	IF EXISTS(SELECT 1 FROM @PORDGLEntryToProcess)
	BEGIN
		--Update the description for the gl entries if they have Trans# still in it. Also update the actdate with the dateposted since
		--that is what is passed to GLDT
		UPDATE vGLEntryTransaction
		SET [Description] = REPLACE([Description], 'Trans#', dbo.vfToString(POTrans)), ActDate = @dateposted
		FROM dbo.vGLEntryTransaction
			INNER JOIN @PORDGLEntryToProcess PORDGLEntryToProcess ON vGLEntryTransaction.GLEntryID = PORDGLEntryToProcess.GLEntryID
	
		--Create all PORDGL records that don't currently exist
		INSERT dbo.vPORDGL (POCo, Mth, POTrans)
		SELECT PORDGLEntryToProcess.POCo, PORDGLEntryToProcess.Mth, PORDGLEntryToProcess.POTrans
		FROM @PORDGLEntryToProcess PORDGLEntryToProcess
			LEFT JOIN dbo.vPORDGL ON PORDGLEntryToProcess.POCo = vPORDGL.POCo AND PORDGLEntryToProcess.Mth = vPORDGL.Mth AND PORDGLEntryToProcess.POTrans = vPORDGL.POTrans
		WHERE vPORDGL.PORDGLID IS NULL
		
		--Update our table variable PORDGLID so that we can then update the PORDGLEntries
		UPDATE PORDGLEntryToProcess
		SET PORDGLID = vPORDGL.PORDGLID
		FROM @PORDGLEntryToProcess PORDGLEntryToProcess
			INNER JOIN dbo.vPORDGL ON PORDGLEntryToProcess.POCo = vPORDGL.POCo AND PORDGLEntryToProcess.Mth = vPORDGL.Mth AND PORDGLEntryToProcess.POTrans = vPORDGL.POTrans
		
		--Update the PORDGLEntries with their PORDGLID so we know what PO Receipt the GL Entry was created for		
		UPDATE vPORDGLEntry
		SET PORDGLID = PORDGLEntryToProcess.PORDGLID
		FROM @PORDGLEntryToProcess PORDGLEntryToProcess
			INNER JOIN dbo.vPORDGLEntry ON PORDGLEntryToProcess.GLEntryID = vPORDGLEntry.GLEntryID
		
		DECLARE @GLEntriesToDelete TABLE (GLEntryID bigint)
		
		--Update PO Receipt GL records with their current PORDGLEntries
		UPDATE vPORDGL
		SET CurrentCostGLEntryID = PORDGLEntryToProcess.GLEntryID
			OUTPUT DELETED.CurrentCostGLEntryID
				INTO @GLEntriesToDelete
		FROM @PORDGLEntryToProcess PORDGLEntryToProcess
			INNER JOIN dbo.vPORDGL ON PORDGLEntryToProcess.PORDGLID = vPORDGL.PORDGLID

		--Get rid of the GL Entries that are no longer pointed to
		DELETE dbo.vGLEntry
		WHERE GLEntryID IN (SELECT GLEntryID FROM @GLEntriesToDelete)

		--Get rid of entries in the batch table.
		DELETE dbo.vGLEntryBatch
		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
	END
	
	exec @rcode=bspPORBExpPostEM @co, @mth, @batchid, @dateposted, @errmsg output
	if @rcode <> 0 goto bspexit
   
	-- make sure all EM Distributions have been processed
	if exists(select * from bPORE with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
		goto bspexit
		end

	exec @rcode=bspPORBExpPostIN @co, @mth, @batchid, @dateposted, @errmsg output
	if @rcode <> 0 goto bspexit
   
	-- make sure all IN Distributions have been processed
	if exists(select * from bPORN with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all updates to IN were posted - unable to close the batch!', @rcode = 1
		goto bspexit
		end
   
-- unlock PO Header and Items that where in this batch
update dbo.bPOHD
	set InUseMth = null, InUseBatchId = null
where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid

update dbo.bPOIT
	set InUseMth = null, InUseBatchId = null
where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid

update dbo.vPOItemLine
	set InUseMth = null, InUseBatchId = null
where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid

--  Update POCo with New Receipt Update Levels.
select @source=Source
from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid

if isnull(@source,'') = 'PO InitRec'
	begin
	-- get PORH info
	Update bPOCO
	Set ReceiptUpdate = h.ReceiptUpdate,
		GLAccrualAcct = h.GLAccrualAcct,
		GLRecExpInterfacelvl = h.GLRecExpInterfacelvl,
		GLRecExpSummaryDesc = h.GLRecExpSummaryDesc, 
		GLRecExpDetailDesc = h.GLRecExpDetailDesc,
		RecJCInterfacelvl = h.RecJCInterfacelvl,
		RecEMInterfacelvl = h.RecJCInterfacelvl,
		RecINInterfacelvl = h.RecINInterfacelvl
	from bPOCO with (nolock)
		join bPORH h on POCo = h.Co
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
	if @@rowcount <> 1
		begin
		select @errmsg = ' Unable to update PO Company Interface levels!', @rcode = 1
		goto bspexit
		end

	end
	
-- set interface levels note string
select @Notes=Notes from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
	'EM Interface Level set at: ' + convert(char(1), a.RecEMInterfacelvl) + char(13) + char(10) +
	'GL Exp Interface Level set at: ' + convert(char(1), a.GLRecExpInterfacelvl) + char(13) + char(10) +
	'IN Interface Level set at: ' + convert(char(1), a.RecINInterfacelvl) + char(13) + char(10) +
	'JC Interface Level set at: ' + convert(char(1), a.RecJCInterfacelvl) + char(13) + char(10),
	@GLRecExpInterfacelvl = a.GLRecExpInterfacelvl
from bPOCO a with (nolock) where POCo=@co

	-- Set vSMDetailTransaction as posted and delete work completed
	EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @GLInterfaceLevel = @GLRecExpInterfacelvl, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode
   
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Notes = @Notes, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode
   
     bspexit:
     	if @PORBopencursor = 1
     		begin
     		close bcPORB
     		deallocate bcPORB
     		end
     	if @PORAopencursor = 1
     		begin
     		close bcPORA
     		deallocate bcPORA
     		end
         if @PORIopencursor = 1
     		begin
     		close bcPORI
     		deallocate bcPORI
     		end
     	return @rcode








GO

GRANT EXECUTE ON  [dbo].[bspPORBPost] TO [public]
GO
