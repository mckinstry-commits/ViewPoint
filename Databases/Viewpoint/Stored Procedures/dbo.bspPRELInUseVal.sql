SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRELInUseVal    Script Date: 8/28/99 9:33:18 AM ******/
   CREATE  procedure [dbo].[bspPRELInUseVal]
   /************************************************************************
    * CREATED BY: EN 1/16/98
    * MODIFIED By : EN 4/3/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * Checks bPREL to see if a particular employee/leave code combination is in
    * use in another batch.
    *
    * PRAB insert trigger will update InUseBatchId in bPRLH *
    *  INPUT PARAMETERS
    *   @co	PR company number
    *   @batchid	Batch ID
    *   @employee	Employee
    *   @leavecode	Leave Code
    *
    * OUTPUT PARAMETERS
    *   @errmsg      error message if error occurs
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *
    *************************************************************************/
   
   	@co bCompany, @batchid bBatchID, @employee bEmployee,
   	@leavecode bLeaveCode, @errmsg varchar(60) output
   
   as
   set nocount on
   declare @rcode int, @inusebatchid bBatchID, @errtext varchar(200)
   
   select @rcode = 0
   
   select @inusebatchid=InUseBatchId from PREL
   where PRCo=@co and Employee=@employee and LeaveCode=@leavecode
   if @inusebatchid is not null and @inusebatchid <> @batchid
   	begin
   	select @errmsg = 'Employee/Leave code already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRELInUseVal] TO [public]
GO
