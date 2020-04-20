SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHQBCUseExisting]
/**************************************************************
* Created: ??
* Modified: 1/11/02 JM - Added exception for EMFuelPosting and EMFuelPostingInit forms re check
*	of Source and TableName.  These two forms must have the same Source but can share
*	each other's TableName.
*	10-03-02 JM - (1) Removed above since both EMFuel forms use 'EMFuel' source rather than 'EMAdj'.
*		(2) Added qualification for EMAdj to permit EMCostAdjustments form to only open 'EMAdj', 
*		'EMAlloc', or 'EMDepr' sources since we use the EMCostAdj form to validate and post Alloc
*		and Depr batches. Was allowing form to open any souce because of code mentioned in (1).
*		RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*		GG - 03/26/07 - #124001 - allow 'viewpointcs' access to restricted batches
*
*
* Validates and locks an existing bHQBC entry for use in a posting form.  
*
* updates inuseby to be current user and returns 0 if OK
* returns 1 and error msg if problem*
* Inputs:
*	@co			Company
*	@mth		Batch Month
*	@batchid	Batch ID#
*	@source		Batch source
*	@tablename	Batch table name
*
* Outputs:
*	@errmsg		Error message
*
* Return code:
*	@rcode = 0 if successful, 1 = if error
*
***************************************************************/
    
    @co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    @source bSource = null,	@tablename char(20) = null, @errmsg varchar(60) output
    
as

set nocount on

declare @bsource bSource, @btablename char(20), @inuseby bVPUserName,
	 @createdby bVPUserName, @status tinyint, @restrict bYN, @rcode int

select @rcode = 0
    
/* validate BatchId */
select @bsource = Source, @btablename = TableName, @inuseby = InUseBy,
	@createdby = CreatedBy, @status = Status, @restrict = Rstrict
from dbo.bHQBC (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid BatchId #!', @rcode = 1
	goto bspexit
	end
    
/* check Source and TableName */
if @bsource <> @source or @btablename <> @tablename
	begin
   	/* special validation needed for EM - added 10-03-02 - See comments header */
   	if @source = 'EMAdj' and (@bsource = 'EMAdj' or @bsource = 'EMAlloc' or @bsource = 'EMDepr')
		select @errmsg = null	-- let it through 
    else	
    	begin
    	select @errmsg = 'This batch is associated with another source!', @rcode = 1
    	goto bspexit
    	end
    end

/* check Status - must be 0 (open) or 6 (canceled) */
if @status <> 0 and @status <> 6
	begin
	select @errmsg = 'Invalid status - must be Open or Canceled.', @rcode = 1
	goto bspexit
	end
    
/* check InUseBy */
if not @inuseby is null
	begin
	select @errmsg = 'This batch is already in use by ' + isnull(@inuseby,''), @rcode = 1
	goto bspexit
	end
    
/* check Restrict */
if @restrict = 'Y' and suser_sname() not in (@createdby,'viewpointcs')
	begin
	select @errmsg = 'This batch is restricted!', @rcode = 1
	goto bspexit
	end

/* all checks complete - set InUseBy to current user */
update dbo.bHQBC 
set InUseBy = SUSER_SNAME(), Status = 0
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update Batch Control information!', @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHQBCUseExisting] TO [public]
GO
