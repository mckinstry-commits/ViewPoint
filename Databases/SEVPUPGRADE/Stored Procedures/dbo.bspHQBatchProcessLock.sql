SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHQBatchProcessLock]
/**************************************************************
* Created: ??
* Modified: GG 03/22/02 - Fix for 'MO Entry' source
*			JM 5-03-02 - Added check to verify there are records in the batch table (looks for Status 6).
*			GF 08/11/2003 - issue #22110 - performance improvements
*			RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*			GG 04/13/07 - #124001 - allow viewpointcs to process restricted batches
*
* Validates an existing bHQBC entry for use in a  processing pgm 
* checks batchid, source, inuseby, status, and restriced flag
* updates inuseby to be current user and returns 0 if OK
*
* Inputs:
*	@co			Company
*	@mth		Batch Month
*	@batchid	Batch ID#
*	@mod		Module
*
* Output:
*	@errmsg		Error message
*
* Returns
*	@rcode		0 = success, 1 = error
*
***************************************************************/

   (@co bCompany, @mth bMonth, @batchid bBatchID, @mod varchar(2), @errmsg varchar(255) output)
   
as
set nocount on

declare @source bSource, @tablename char(30), @inuseby bVPUserName,
	@createdby bVPUserName, @status tinyint, @restrict bYN, @prgroup bGroup,
	@prenddate bDate, @rcode int, @sql varchar(255)

select @rcode = 0

-- validate BatchId
select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   @createdby = CreatedBy, @status = Status, @restrict = Rstrict, 
   @prgroup=PRGroup, @prenddate=PREndDate
from dbo.bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid BatchId #!', @rcode = 1
	goto bspexit
	end

--check Source - exception added for IN Material Orders
if substring(@source,1,2) <> @mod and (@mod <> 'IN' and substring(@source,1,2) = 'MO') 
	begin
	select @errmsg = 'This batch is not associated with a ' + isnull(@mod,'') + ' source!', @rcode = 1
	goto bspexit
	end
   
-- check Tablename
if substring(@tablename,1,2) <> @mod
	begin
	select @errmsg = 'This batch is not associated with a ' + isnull(@mod,'') + ' batch table!', @rcode = 1
	goto bspexit
	end

-- Make sure there are records in the batch table - Status will be 6 if none
if @status = 6 -- canceled 
	begin
	select @errmsg = 'Cannot process an empty batch!', @rcode = 1
	goto bspexit
	end
   
-- check Status - must be 0 (open) or 4 (update in progress)
if @status <> 0 and @status <> 3 and @status <> 4
	begin
	select @errmsg = 'Invalid status - must be ''open'' or ''update in progress''.', @rcode = 1
	goto bspexit
	end

-- check InUseBy
if @inuseby is not null and @inuseby <> SUSER_SNAME()
	begin
	select @errmsg = 'This batch is already in use by ' + isnull(@inuseby,''), @rcode = 1
	goto bspexit
	end

-- check Restrict
if @restrict = 'Y' and @createdby <> SUSER_SNAME() and suser_sname() <> 'viewpointcs' -- allow viewpointcs to process restricted batches
	begin
	select @errmsg = 'This batch is restricted!', @rcode = 1
	goto bspexit
	end
   
-- all checks complete - set InUseBy to current user
update bHQBC 
set InUseBy = SUSER_SNAME()
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update Batch Control information!', @rcode = 1
	goto bspexit
	end

-- select some descriptive info to return to processing program */
select Source, TableName, DateCreated, CreatedBy, Status, DatePosted, PRGroup, PREndDate
from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
      
   
bspexit:
   --if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + char(13) + char(10) + '[bspHQBatchProcessLock]'
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHQBatchProcessLock] TO [public]
GO
