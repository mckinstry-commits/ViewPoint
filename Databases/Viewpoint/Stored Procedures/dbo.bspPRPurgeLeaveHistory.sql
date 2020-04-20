SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeLeaveHistory    Script Date: 8/28/99 9:35:38 AM ******/
   CREATE procedure [dbo].[bspPRPurgeLeaveHistory]
   /***********************************************************
    * CREATED BY: EN 5/29/98
    * MODIFIED By : EN 5/29/98
    *
    * USAGE:
    * Purges entries from PRLH through a specified month.  Optionally
    * will purge only for a specified leavecode.
    * 
    * INPUT PARAMETERS
    *   @PRCo		PR Company
    *   @Month		Month to purge through
    *   @LeaveCode		Leave code to restrict by (optional)
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   
   	(@PRCo bCompany, @Month bMonth, @LeaveCode bLeaveCode,
   	 @errmsg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   
   select @rcode = 0
   
   
   delete from bPRLH
   where PRCo=@PRCo and Mth<=@Month and LeaveCode=isnull(@LeaveCode,LeaveCode)
   
   		
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeLeaveHistory] TO [public]
GO
