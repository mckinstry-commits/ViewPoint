SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspPORSInsert]
/***********************************************************
* CREATED BY: DANF 05/22/01
* MODIFIED By : DANF 05/1/02 Added update to PORH
*               DANF 06/13/02 Added GL Accural Accounts
*    			 DANF 06/06/03 Corrected Order of New and Old GL accural Accounts
*				DC 2/8/06  Changed the GLInterface level check so it would only 
*							execute if it went from None to Detail/Summary or from 
*							Detail/Summary to None.
*				DC 10/31/08 - #121427 - Can pull PO's into a batch when already in use in AP Batch
*				MH 04/20/11 - Modified for SM.
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 08/24/2011 TK-07879 PO ITEM LINE
*				JVH 7/23/13 Modified to support SM lines
*
*
*
* USAGE:
* This procedure is used by the PO Expense Receipts to Intialize expanses when turning the Update Receipts
* from the PO Company form. This will create a batch of entries, expenses.
* from bPOIT and vPOItemLine into PORS.
*
* Checks batch info in bHQBC, and transaction info in bPOIT.
* Adds entry to next available Seq# in bPORS
*
* PORS insert trigger will update InUseBatchId in bPOIT
*
* INPUT PARAMETERS
*   POCo	PO Co to Validate
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into

* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/   
@co bCompany, 
@mth bMonth, 
@batchid bBatchID,
@jcinterfacenew tinyint, 
@eminterfacenew tinyint,
@ininterfacenew tinyint, 
@glinterfacenew tinyint,
@jcinterfaceold tinyint, 
@eminterfaceold tinyint,
@ininterfaceold tinyint, 
@glinterfaceold tinyint,
@updateonreceiptold bYN, 
@updateonreceiptnew bYN,
@glsummaryold varchar(60), 
@glsummarynew varchar(60),
@gldetailold varchar(60), 
@gldetailnew varchar(60),
@glaccuralnew bGLAcct, 
@glaccuralold bGLAcct,
@errmsg varchar(255) output

AS      
SET NOCOUNT ON
   
declare @rcode int, @tablename char(20), @inuseby bVPUserName, @dtsource bSource,
		@inusebatchid bBatchID, @seq int, @PO varchar(30), @POItem bItem,
		@recvdunits bUnits, @recvdcost bDollar, @invunits bUnits,
		@invcost bDollar, @invtax bDollar, @itemtype tinyint,
		@source bSource, @status tinyint, @um bUM, @upcost bDollar,
		@upunits bUnits, @orgunitcost bUnitCost, @batchseq int,
		@postatus tinyint, @inusemth bMonth, @update int,
		@origecm bECM, @factor smallint, @inusecount INT,  --DC #121427
		----TK-07879
		@POITKeyID BIGINT, @POItemLine INT

SET @rcode = 0
SET @inusecount = 0  --DC #121427

  
/* validate HQ Batch */
select @source = Source, @tablename = TableName, @inuseby = InUseBy,@status = Status
from bHQBC 
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
	goto bspexit
	end
if @source <> 'PO InitRec'
	begin
	select @errmsg = 'Invalid Batch source - must be (PO Receipt)!', @rcode = 1
	goto bspexit
	end
if @tablename <> 'PORS'
	begin
	select @errmsg = 'Invalid Batch table name - must be (PORS)!', @rcode = 1
	goto bspexit
	end
if @inuseby <> SUSER_SNAME()
	begin
	select @errmsg = 'Batch already in use by ' + @inuseby, @rcode = 1
	goto bspexit
	end
if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
	goto bspexit
	end
  
---- delete PORH
delete dbo.bPORH
where Co = @co and Mth = @mth and BatchId = @batchid

insert into bPORH (Co, Mth, BatchId, ReceiptUpdate, GLRecExpInterfacelvl, GLRecExpSummaryDesc, GLRecExpDetailDesc, RecJCInterfacelvl, RecEMInterfacelvl, RecINInterfacelvl, OldReceiptUpdate, OldGLRecExpInterfacelvl, OldGLRecExpSummaryDesc, OldGLRecExpDetailDesc, OldRecJCInterfacelvl, OldRecEMInterfacelvl, OldRecINInterfacelvl, OldGLAccrualAcct, GLAccrualAcct)
values ( @co, @mth, @batchid, @updateonreceiptnew, @glinterfacenew, @glsummarynew, @gldetailnew, @jcinterfacenew, @eminterfacenew, @ininterfacenew, @updateonreceiptold, @glinterfaceold, @glsummaryold, @gldetailold, @jcinterfaceold, @eminterfaceold, @ininterfaceold, @glaccuralold, @glaccuralnew  )

---- delete PORS
delete dbo.bPORS
from dbo.bPORS
where Co = @co


---- TK-07869
---- pseudo cursor to initialize expenses
---- PO
SELECT @PO = MIN(PO) FROM dbo.bPOIT WHERE POCo = @co AND RecvYN = 'Y'
WHILE @PO IS NOT NULL
	BEGIN

	---- PO Item
	SELECT @POItem = MIN(POItem) FROM dbo.bPOIT WHERE POCo = @co AND RecvYN = 'Y' AND PO = @PO
	WHILE @POItem IS NOT NULL
	BEGIN
		
		---- get POIT info
		SELECT  @um = UM, @orgunitcost = OrigUnitCost, @origecm = OrigECM,
				@inusebatchid = InUseBatchId, @inusemth = InUseMth,  --DC #121427
				@POITKeyID = KeyID
		FROM dbo.bPOIT
		WHERE POCo=@co
			AND PO=@PO
			AND POItem=@POItem 

		---- PO Item Line
		SELECT @POItemLine = MIN(POItemLine) FROM dbo.vPOItemLine WHERE POITKeyID = @POITKeyID
		WHILE @POItemLine IS NOT NULL
		BEGIN

			---- get POItemLine info always line 1
			SELECT  @recvdunits = RecvdUnits, @recvdcost = RecvdCost,
					@invunits = InvUnits, @invcost = InvCost,
					@invtax = InvTax, @itemtype = ItemType
			FROM dbo.vPOItemLine 
			WHERE POITKeyID = @POITKeyID
				AND POItemLine = @POItemLine

			----DC #121427
			IF @inusebatchid is not null AND @inusemth is not null 
				begin
				select @inusecount = @inusecount + 1
				goto next_poit
				end

			SET @update = 1
   
			--- check Item type
			If @itemtype = 1
				begin
				if @jcinterfacenew = @jcinterfaceold goto next_poit
				if @jcinterfacenew = 0 and @jcinterfaceold > 0 select @update = -1
				end
			If @itemtype = 2
				begin
				if @ininterfacenew = @ininterfaceold  goto next_poit
				if @ininterfacenew = 0 and @ininterfaceold > 0 select @update = -1
				end
			If (@itemtype = 3 or @itemtype = 6)
				begin
				if @glinterfacenew = @glinterfaceold  goto next_poit
				--DC 28288 Start
				if @glinterfacenew = 2 and @glinterfaceold = 1 goto next_poit
				if @glinterfacenew = 1 and @glinterfaceold = 2 goto next_poit
				--END
				if @glinterfacenew = 0 and @glinterfaceold > 0 select @update = -1			 
				end			
			If (@itemtype = 4 or @itemtype = 5)
				begin
				if @eminterfacenew = @eminterfaceold goto next_poit
				if @eminterfacenew = 0 and @eminterfaceold > 0 select @update = -1
				end
				
			--- check recvd vs inv
			select @upunits = 0, @upcost = 0
			select @factor = case @origecm when 'C' then 100 when 'M' then 1000 else 1 end
   
			If @um = 'LS'
				begin
				If @recvdcost <= @invcost goto next_poit
				select @upcost = (@recvdcost - @invcost) * @update
				end
			else
				begin
				If @recvdunits <= @invunits goto next_poit
				select @upunits = (@recvdunits - @invunits) * @update
				select @upcost = ((@orgunitcost * @upunits)/@factor) * @update
				end
   
			-- all PO's can be pulled into a batch as long as it's
			-- The header is on file and the po is not pending
			select @inusebatchid = InUseBatchId, @inusemth = InUseMth, @postatus = Status
			from dbo.bPOHD 
			where POCo=@co
				AND PO=@PO
			if @@rowcount = 0 goto next_poit
   
			if @postatus <> 0 goto next_poit
   
			-- insert Receiving Records
    		select @batchseq = isnull(max(BatchSeq),0) + 1
			from dbo.bPORS
			where Co = @co and Mth = @mth and BatchId = @batchid
   
			---- insert into PORS
			insert into dbo.bPORS (Co, Mth, BatchId, BatchSeq, PO, POItem, RecvdUnits, RecvdCost, POItemLine )
            values (@co, @mth, @batchid, @batchseq, @PO, @POItem, @upunits, @upcost, @POItemLine)


		next_poit:

		---- next PO Item Line
		SELECT @POItemLine = MIN(POItemLine) from dbo.vPOItemLine WHERE POITKeyID=@POITKeyID AND POItemLine > @POItemLine
		IF @@ROWCOUNT = 0 SET @POItemLine = NULL
		END

	---- next PO Item
	SELECT @POItem = MIN(POItem) from dbo.bPOIT WHERE POCo=@co and RecvYN='Y' and PO=@PO and POItem>@POItem
	IF @@ROWCOUNT = 0 SET @POItem = NULL
	END

---- next PO
SELECT @PO = MIN(PO) FROM dbo.bPOIT WHERE POCo = @co AND RecvYN = 'Y' AND PO > @PO
IF @@ROWCOUNT = 0 SET @PO = NULL
END
  
  
  
bspexit:
	--DC #121427
	IF @inusecount <> 0 AND @rcode = 0
	BEGIN
	SELECT @errmsg = convert(varchar(6),@inusecount) + ' POs exists in either PO or AP batches and are not included in this batch.'
	END

	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPORSInsert] TO [public]
GO
