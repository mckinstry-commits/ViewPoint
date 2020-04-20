SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREndDateVal    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE  proc [dbo].[bspPREndDateVal]
   /***********************************************************
    * CREATED BY: EN 12/18/97
    * MODIFIED By : EN 4/3/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * Validates PR Ending Date from PRPC
    * an error is returned if it is not found, or Status incorrect
    *
    * INPUT PARAMETERS
    *   @prco	PR Co to validate against 
    *   @prgroup	PR Group to use in validation
    *   @enddate	PR Ending Date
    *   @statusopt	Controls validation based on Pay Period Status
    *   		'0' = Must be Open
    *		'1' = Must be Closed
    *		'3' = Can be either Open or Closed
    *		
    * OUTPUT PARAMETERS
    *   @msg	error message if error occurs
    *
    * RETURN VALUE
    *   0		success
    *   1          Failure
    *****************************************************/ 
   
   (@prco bCompany, @prgroup bGroup, @enddate bDate, @statusopt varchar(1), @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint
   
   select @rcode = 0
   
   select @status=Status from PRPC where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate
   
   if @@rowcount=0
   	begin
   	select @msg = 'Invalid Pay Period Ending Date!', @rcode = 1
   	goto bspexit
   	end
   
   if @statusopt = '0' and @status <> 0
   	begin
   	select @msg = 'Must be an Open Pay Period!', @rcode = 1
   	goto bspexit
   	end
   
   if @statusopt = '1' and @status <> 1
   	begin
   	select @msg = 'Must be a Closed Pay Period!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREndDateVal] TO [public]
GO
