SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspPORSPost]
/************************************************************************
* Created: DANF 05/23/01
* Modified by: CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*              DANF 07/22/02 - Added removal of PORH.
*              DANF 01/08/03 - Added Update of PO Company with new Levels.
*				 DC  #128052  10/22/08 - Remove Committed Cost Flag
*				 GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*			GF 08/23/2011 TK-07879 PO ITEM LINE
*				JVH 7/23/13 Modified to support SM lines
*
*
*
* Posts a validated batch of PO Expense Receipt Initialize entries.  Updates
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
   
declare @rcode int, @status tinyint, --@cmtddetailtojc bYN, DC #128052
		@errorstart varchar(60),
		@PORSopencursor tinyint,
		@vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup, @material bMatl,
		@keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128)

 -- PORS declares
 declare @seq int, @transtype char(1), @potrans bTrans, @po varchar(30), @poitem bItem, @recvddate bDate,
		 @recvdby char(10),  @description bDesc, @recvdunits bUnits, @recvdcost bDollar, @bounits bUnits,
		 @bocost bDollar, @oldpo varchar(30), @oldpoitem bItem, @oldrecvddate bDate, @oldrecvdby varchar(10),
		 @olddesc bDesc, @oldrecvdunits bUnits, @oldrecvdcost bDollar, @oldbounits bUnits, @oldbocost bDollar,
		 @Receiver# varchar(20), @OldReceiver# varchar(20), @InvdFlag bYN, @OldInvdFlag bYN

-- PORA declares
declare @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @oldnew tinyint,
		@um bUM, @jcum bUM, @rniunits bUnits, @rnicost bDollar, @cmtdunits bUnits, @cmtdcost bDollar, @jctrans bTrans

-- PORI delcares
declare @inco bCompany, @loc bLoc, @onorder bUnits

----TK-07879
DECLARE @POItemLine INT

select @rcode = 0
   
     /* check for date posted */
     if @dateposted is null
     	begin
     	select @errmsg = 'Missing posting date!', @rcode = 1
     	goto bspexit
     	end
   
     /* validate HQ Batch */
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'PORS', @errmsg output, @status output
     if @rcode <> 0
     	begin
         select @rcode = 1
         goto bspexit
        	end
   
     if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
     	begin
     	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
     	goto bspexit
     	end
   
     /* set HQ Batch status to 4 (posting in progress) */
     update bHQBC
     set Status = 4, DatePosted = @dateposted
     where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
   

   
   
          exec @rcode=bspPORBExpPostJC @co, @mth, @batchid, @dateposted, @errmsg output
          if @rcode <> 0 goto bspexit
   
          -- make sure all JC Distributions have been processed
          if exists(select * from bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid)
              begin
              select @errmsg = 'Not all updates to JC were posted - unable to close the batch!', @rcode = 1
              goto bspexit
              end
   
          exec @rcode=bspPORBExpPostGL @co, @mth, @batchid, @dateposted, @errmsg output
          if @rcode <> 0 goto bspexit
   
          -- make sure all GL Distributions have been processed
          if exists(select * from bPORG where POCo = @co and Mth = @mth and BatchId = @batchid)
              begin
       	    select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
       	    goto bspexit
       	    end
   
   
          exec @rcode=bspPORBExpPostEM @co, @mth, @batchid, @dateposted, @errmsg output
          if @rcode <> 0 goto bspexit
   
          -- make sure all EM Distributions have been processed
          if exists(select * from bPORE where POCo = @co and Mth = @mth and BatchId = @batchid)
            begin
       	    select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
       	    goto bspexit
       	    end
   
   
   
          exec @rcode=bspPORBExpPostIN @co, @mth, @batchid, @dateposted, @errmsg output
       if @rcode <> 0 goto bspexit
   
          -- make sure all IN Distributions have been processed
          if exists(select * from bPORN where POCo = @co and Mth = @mth and BatchId = @batchid)
              begin
       	    select @errmsg = 'Not all updates to IN were posted - unable to close the batch!', @rcode = 1
       	    goto bspexit
       	    end
   
-- delete current entry from batch
delete bPORS
where Co = @co and Mth = @mth and BatchId = @batchid


-- make sure batch tables are empty
if exists(select * from bPORS where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all PO Receipt batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end
   
-- unlock PO Header and Items that where in this batch
update bPOHD
set InUseMth = null, InUseBatchId = null
where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid

update bPOIT
set InUseMth = null, InUseBatchId = null
where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid

---- update PO Item Line and unlock TK-07879
UPDATE dbo.vPOItemLine
	SET	InUseBatchId = NULL, InUseMth = NULL
WHERE POCo = @co
	AND InUseMth = @mth
	AND InUseBatchId = @batchid

DECLARE @GLRecExpInterfacelvl tinyint

SELECT @GLRecExpInterfacelvl = CASE WHEN OldGLRecExpInterfacelvl > 1 AND GLRecExpInterfacelvl = 0 THEN OldGLRecExpInterfacelvl ELSE GLRecExpInterfacelvl END
FROM dbo.bPORH
WHERE Co = @co AND Mth = @mth AND BatchId = @batchid

-- Set vSMDetailTransaction as posted and delete work completed
EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @GLInterfaceLevel = @GLRecExpInterfacelvl, @msg = @errmsg OUTPUT
IF @rcode <> 0 RETURN @rcode

--Capture set Status to posted and cleanup HQCC records
EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @msg = @errmsg OUTPUT
IF @rcode <> 0 RETURN @rcode

exec @rcode=bspPORHPost @co, @mth, @batchid, @source, @errmsg output
if @rcode <> 0            
	begin
	select @errmsg = 'Unable to update PO Company with new interface levels!', @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPORSPost] TO [public]
GO
