SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspAPBatchClear]
/*************************************************************************************************
* CREATED: kf 10/22/97
* MODIFIED: GG 4/30/99
*			GR 10/23/00 - Added code to delete any associated attachments
*           DANF 05/24/01 - Added code to delete any Receipte Expense distributions.
*           TV 10/25/01 - Attachments should not be deleted if there are APUI entries issue 14944
*			RM 02/21/02 - Modified attachment Process
*			MV 10/18/02 - 18878 quoted identifier cleanup
*			MV 11/26/03 - 23061 wrap concatenated strings in isnulls
*			GG 06/11/07 - #120561 - delete from tables instead of views, cleanup
*			MV 06/01/09 - #122431 - don't update form and table name in HQAT for unapproved per issue #127603
*			MH 04/13/11 - TK-04244 - Include SM distribution table (vAPSM) in clear.
*           DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
*			
* USAGE:
* Clears batch tables
*
* INPUT PARAMETERS
*   APCo        AP Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/

	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
as

set nocount on

declare @rcode int, @tablename char(20), @status tinyint, @inuseby bVPUserName 

select @rcode = 0
   
select @status=Status, @inuseby=InUseBy, @tablename=TableName
from dbo.bHQBC 
where Co=@co and Mth=@mth and BatchId=@batchid
if @@rowcount=0
	begin
	select @errmsg='Invalid batch.', @rcode=1
	goto bspexit
	end
if @status=5
	begin
	select @errmsg='Cannot clear, batch has already been posted!', @rcode=1
	goto bspexit
	end
if @status=4
	begin
	select @errmsg='Batch posting was interrupted, cannot clear!', @rcode=1
	goto bspexit
	end
if @inuseby<>SUSER_SNAME()
	begin
	select @errmsg='Batch is already in use by @inuseby ' + isnull(@inuseby,'') + '!', @rcode=1
	goto bspexit
	end
   
if @tablename='APPB'	-- payment batches
	begin
	delete from dbo.bAPPG where APCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPDB where Co=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPTB where Co=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPPB where Co=@co and Mth=@mth and BatchId=@batchid
	end

if @tablename='APHB'	-- invoice batches
	begin
	-- update Attachment info for Unapproved Invoices to prevent loss of attacthments
--	update dbo.bHQAT
--	set FormName='APUnappInv', TableName = 'APUI'
--	from dbo.bHQAT t
--	join dbo.bAPHB b on t.UniqueAttchID = b.UniqueAttchID
--	join dbo.bAPUI i on i.APCo=b.Co and i.InUseBatchId = b.BatchId and i.InUseMth = b.Mth
--	where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid
   
	-- purge data from invoice batch and distribution tables, triggers will unlock existing trans
	delete from dbo.bAPIN where APCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPJC where APCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPEM where APCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPGL where APCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPLB where Co=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPHB where Co=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bPORE where POCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bPORJ where POCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bPORG where POCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bPORN where POCo=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.vAPSM where APCo=@co and Mth=@mth and BatchId=@batchid
	DELETE dbo.vHQBatchDistribution
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
	
	end
  
if @tablename='APCT'	-- clear transactions batch
	begin
	delete from dbo.bAPCD where Co=@co and Mth=@mth and BatchId=@batchid
	delete from dbo.bAPCT where Co=@co and Mth=@mth and BatchId=@batchid
	end

-- update Batch status to 6=canceled, bHQCC entries removed by bHQBC trigger   
update dbo.bHQBC set Status=6
where Co=@co and Mth=@mth and BatchId=@batchid
   
 
bspexit:
    return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPBatchClear] TO [public]
GO
