SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************/
CREATE  proc [dbo].[bspPOXBAdd]
/***********************************************************
* CREATED BY: kf 5/13/97
* MODIFIED By : kb 2/25/99
*               GG 11/05/99 - Cleanup
*               GR 02/07/00 - Corrected the where clause if JCCo and Job are null
*               kb 5/22/01 - wasn't accumulating remaining cost for all items, just the last issue #11936
*               kb 10/1/1 - issue #14730
*				MV 06/03/04 - #24720 - return batch info if PO already in a close batch.
*				MV 01/18/05 - #21093 - close open standing POs if flag is checked in PO Close form.
*				DC 05/06/2009 - #133258 - Close ignoring "include open standing POs" flag
*				TRL  07/27/2011 TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 09/06/2011 TK-08203 PO ITEM LINE ENHANCEMENT
*				GF 11/18/2011 TK-10121 
*
*
*
* Called by the PO Close program to find POs eligible for closing.
* Loads and/or clears bPOXB.
*
* INPUT PARAMETERS:
*  @co             PO Company #
*  @mth            Batch Month
*  @batchid        Batch ID#
*  @getvendor      Vendor - used to restrict POs
*  @getjcco        JC Company - used to restrict POs
*  @getjob         Job - used to restrict POs
*  @beginpo        Beginning PO - used for range
*  @endpo          Ending PO - used for range
*  @addordelete    'A' = add POs to batch, 'D' = remove all POs from batch,
*                  'R' = remove a range of POs from batch
*  @boflag         'Y' = include POs with Backorders, 'N' = skip POs with Backorders
*  @closedate      Close Date
*  @closestanding	YN flag to indicate if standing POs should be closed.
*
*
* OUTPUT PARAMETERS:
*   @errrmsg       error message
*
* RETURN VALUE
*   @rcode         0 = success, 1 = error
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @getvendor bVendor, @getjcco bCompany,
 @getjob bJob, @beginpo VARCHAR(30), @endpo varchar(30), @addordelete CHAR(1),
 @boflag bYN, @closedate bDate, @closestanding bYN = null,
 @errmsg varchar(255) output)
AS
SET NOCOUNT ON

declare @rcode INT, @seq INT, @POXBopencursor TINYINT, @vendor bVendor, @jcco bCompany,
		@job bJob, @po VARCHAR(30), @vendorgroup bGroup, @remcost bDollar, @description bDesc,
		@status TINYINT, @inusebatchid INT, @inusemth bMonth,
		---- TK-08203
		@RecvdCost bDollar, @RecvdUnits bUnits, @InvCost bDollar, @InvUnits bUnits,
		@BOCost bDollar, @BOUnits bUnits, @UM bUM, @source bSource
		
		
SET @rcode = 0
SET	@POXBopencursor = 0

IF @beginpo IS NULL SET @beginpo = ''
IF @endpo IS NULL SET @endpo = '~~~~~~~~~~'
IF @closestanding IS NULL SET @closestanding = 'N'

---- remove all entries from the batch
IF @addordelete = 'D'
	BEGIN
	DELETE FROM dbo.POXB WHERE Co = @co and Mth = @mth and BatchId = @batchid
	DELETE FROM dbo.POXA WHERE POCo = @co and Mth = @mth and BatchId = @batchid
	DELETE FROM dbo.POXI WHERE POCo = @co and Mth = @mth and BatchId = @batchid
	GOTO bspexit
	END
	
---- remove a range of POs from the batch
IF @addordelete = 'R'
	BEGIN
	DELETE FROM dbo.POXB WHERE Co = @co and Mth = @mth and BatchId = @batchid and PO >= @beginpo and PO <= @endpo
	DELETE FROM dbo.POXA WHERE POCo = @co and Mth = @mth and BatchId = @batchid and PO >= @beginpo and PO <= @endpo
	DELETE FROM dbo.POXI WHERE POCo = @co and Mth = @mth and BatchId = @batchid and PO >= @beginpo and PO <= @endpo
	GOTO bspexit
	END

---- create a cursor to find POs eligible to close
IF (@getjcco IS NOT NULL and @getjob IS NOT NULL)
    BEGIN
    declare bcPOXB cursor for
    SELECT PO, VendorGroup, Vendor, Description, Status, JCCo, Job, InUseBatchId, InUseMth
    FROM dbo.POHD
    WHERE POCo = @co
		AND PO >= @beginpo 
		AND PO <= @endpo
		AND Status in ('0','1')  -- 'open' or 'completed'
        AND Vendor = isnull(@getvendor,Vendor)
        AND JCCo = @getjcco
        AND Job = @getjob
		---- and InUseBatchId is null and InUseMth is null   -- skip if already locked
    END
else
    BEGIN
    declare bcPOXB cursor for
    SELECT PO, VendorGroup, Vendor, Description, Status, JCCo, Job, InUseBatchId, InUseMth
    FROM dbo.POHD
    WHERE POCo = @co
		AND PO >= @beginpo
		AND PO <= @endpo
		AND Status in ('0','1')  -- 'open' or 'completed'
        AND Vendor = isnull(@getvendor,Vendor)
		---- and InUseBatchId is null and InUseMth is null   -- skip if already locked
    END   

open bcPOXB
SET @POXBopencursor = 1      -- set open cursor flag

POXB_loop:  -- process each PO
fetch next from bcPOXB INTO @po, @vendorgroup, @vendor, @description, @status, @jcco, @job, @inusebatchid ,@inusemth

IF @@fetch_status <> 0 GOTO POXB_end


---- TK-08203
SET @RecvdCost = 0
SET @RecvdUnits = 0
SET @InvCost = 0
SET @InvUnits = 0
SET @BOCost = 0
SET @BOUnits = 0
---- Received must equal Invoiced
SELECT  @RecvdCost	= CASE WHEN i.UM = 'LS' THEN SUM(l.RecvdCost) END,
		@InvCost	= CASE WHEN i.UM = 'LS' THEN SUM(l.InvCost) END,
		@RecvdUnits = CASE WHEN i.UM <> 'LS' THEN SUM(l.RecvdUnits) END,
		@InvUnits	= CASE WHEN i.UM <> 'LS' THEN SUM(l.InvUnits) END,
		@BOCost		= CASE WHEN i.UM = 'LS' THEN SUM(l.BOCost) END,
		@BOUnits	= CASE WHEN i.UM <> 'LS' THEN SUM(l.BOUnits) END
FROM dbo.POItemLine l
INNER JOIN dbo.POIT i ON i.KeyID = l.POITKeyID
WHERE l.POCo = @co
	AND l.PO = @po
GROUP BY l.POCo, l.PO, i.POItem, l.POItemLine, i.UM
	
IF exists(SELECT 1 FROM dbo.POIT WHERE POCo = @co and PO = @po and UM = 'LS' and RecvdCost <> InvCost) goto POXB_loop      -- use Cost if 'LS'
IF exists(SELECT 1 FROM dbo.POIT WHERE POCo = @co and PO = @po and UM <> 'LS' and RecvdUnits <> InvUnits) goto POXB_loop    -- use Units if not 'LS'
---- TK-08203
--if @RecvdCost <> @InvCost GOTO POXB_loop
--if @RecvdUnits <> @InvUnits GOTO POXB_loop


---- check for Backordered - only applies to 'open' POs
IF @status = 0 and @boflag = 'N'
	BEGIN
	----TK-10121
	IF exists(SELECT 1 FROM dbo.POIT WHERE POCo = @co and PO = @po and UM = 'LS' and BOCost <> 0) goto POXB_loop      -- use Cost if 'LS'
	IF exists(SELECT 1 FROM dbo.POIT WHERE POCo = @co and PO = @po and UM <> 'LS' and BOUnits <> 0) goto POXB_loop    -- use Units if not 'LS'
	---- TK-08203
	----IF @BOCost <> 0 GOTO POXB_loop
	----IF @BOUnits <> 0 GOTO POXB_loop
	END


/* check for blanket PO's Set the rule that if any line on the PO has zero
current units and a unit cost that is not zero, don't update the PO to the
close table if the status is open.  The user must first set the status as Complete (2)
before closing. - issue #14730*/
IF @closestanding = 'N'
	BEGIN
	----TK-10121
	----TK-08203
	----IF @status = 0
	----	BEGIN
	----	IF EXISTS(SELECT 1 FROM dbo.POItemLine l JOIN dbo.POIT i ON i.KeyID = l.POITKeyID
	----			WHERE l.POCo = @co
	----				AND l.PO = @po
	----				AND l.CurUnits = 0
	----				AND i.CurUnitCost <> 0)
	----		BEGIN
	----		GOTO POXB_loop
	----		END
	----	END
		
	----DC #133258  This issue was to reverse issue 14730.  We now WILL include standing PO's
    IF @status = 0 AND EXISTS(SELECT 1 FROM dbo.POIT WHERE POCo = @co and PO = @po and CurUnits = 0 and CurUnitCost <> 0) goto POXB_loop         	    
	END


---- get Total Remaining Cost - include Tax
----TK-08203
SET @remcost = 0
SELECT @remcost = @remcost + ISNULL(SUM(RemCost),0) + ISNULL(SUM(RemTax),0)
FROM dbo.POItemLine
----FROM dbo.POIT
WHERE POCo = @co 
	AND PO = @po


   		--select @source=Source
   	 --   from HQBC with (nolock)
   		--where Co=@poco and Mth=@InUseMth and BatchId=@InUse 
   		--if @@rowcount<>0
   		--	begin
   		--	select @msg = 'PO item already in use by ' +
   		--	      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' + 
   		--	      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) + 
   		--		' batch # ' + convert(varchar(6),@InUse) + ' - ' + 'Batch Source: ' 
   		--		+ @source, @rcode = 1
   		--	goto bspexit
   		--	end

---- check if already in another batch
IF @inusebatchid IS NOT NULL AND @inusemth IS NOT NULL
    BEGIN 
	SELECT @source = Source
	FROM dbo.HQBC WITH (NOLOCK)
	WHERE Co = @co
		AND Mth = @inusemth
		AND BatchId = @inusebatchid
	IF @@ROWCOUNT <> 0
		BEGIN
   		SELECT @errmsg = 'PO: ' + dbo.vfToString(@po) + ' already in use for Month: '
   					+ convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4)
   					+ ' Batch Id: ' + convert(varchar(10), @inusebatchid) + ' Source: ' + ISNULL(@source,'') + '.'
   		SET @rcode = 1
   		GOTO POXB_loop
   		END
   	ELSE
   		BEGIN
   		SELECT @errmsg = 'PO: ' + dbo.vfToString(@po) + ' already in Close Batch: '
   				+ dbo.vfToString(@inusebatchid) + ' Month: ' + convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4)
   		SET @rcode = 1
		GOTO POXB_loop 
		END
	END
	
---- update PO Close Batch
--IF @inusebatchid IS NOT NULL AND @inusemth IS NOT NULL
--    BEGIN
--	SELECT @errmsg = 'PO: ' + dbo.vfToString(@po) + ' already in Close Batch: ' + convert(varchar(10), @inusebatchid) + 
--		' Month: ' + convert (varchar(12), @inusemth, 1), @rcode = 1
--	GOTO POXB_loop 
--    END
        
-- get next available Batch Seq
SELECT @seq = isnull(max(BatchSeq),0) + 1
FROM dbo.POXB
WHERE Co = @co 
	AND Mth = @mth
	AND BatchId = @batchid

---- INSERT BATCH RECORD
INSERT dbo.POXB (Co, Mth, BatchId, BatchSeq, PO, VendorGroup, Vendor, Description,
			JCCo, Job, Remaining, CloseDate)
VALUES (@co, @mth, @batchid, @seq, @po, @vendorgroup, @vendor, @description,
			@jcco, @job, @remcost, @closedate)


GOTO POXB_loop


POXB_end:
    CLOSE bcPOXB
    DEALLOCATE bcPOXB
    SET	@POXBopencursor = 0



bspexit:
    IF @POXBopencursor = 1
        BEGIN
  		CLOSE bcPOXB
  		DEALLOCATE bcPOXB
  		END

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPOXBAdd] TO [public]
GO
