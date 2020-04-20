SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPaidMonthVal    Script Date: 8/28/99 9:35:35 AM ******/
   CREATE  proc [dbo].[bspPRPaidMonthVal]
   /***********************************************************
    * CREATED BY: EN 3/4/98
    * MODIFIED By : GG 3/19/99
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *  Validate that the specified month equals either the BeginMth or EndMth in
    *  the specified pay period in PRPC.
    *  * Input params:
    *	@prco		PR company
    *	@prgroup 	PR Group
    * 	@prenddate	PR Ending Date
    *	@mth		Month
    *
    * Output params:
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/ 
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @mth bMonth, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @beginmth bMonth, @endmth bMonth
   select @rcode = 0
   
   /* check required input params */	
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company.', @rcode = 1
   	goto bspexit
   	end
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group.', @rcode = 1
   	goto bspexit
   	end
   
   if @prenddate is null
   	begin 	select @msg = 'Missing PR Ending Date.', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @msg = 'Missing Month.', @rcode = 1
   	goto bspexit
   	end
   	
   select @beginmth=BeginMth, @endmth=EndMth from bPRPC where PRCo=@prco and PRGroup=@prgroup
   	and PREndDate=@prenddate
   if @@rowcount=0 
   	begin
   	select @msg='Invalid Pay Period.', @rcode=1
   	goto bspexit
   	end
   
   if @mth<>@beginmth and @mth<>isnull(@endmth,@beginmth)
   	begin
   	select @msg =  'Paid month must be ' + substring(convert(varchar(8),@beginmth,3),4,5)
   	if @endmth is not null select @msg = @msg + ' or ' + substring(convert(varchar(8),@endmth,3),4,5)
   	select @rcode = 1
   	goto bspexit
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPaidMonthVal] TO [public]
GO
