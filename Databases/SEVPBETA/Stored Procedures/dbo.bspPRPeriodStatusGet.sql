SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPeriodStatusGet    Script Date: 8/28/99 9:33:33 AM ******/
   CREATE    proc [dbo].[bspPRPeriodStatusGet]
   
   /***********************************************************
    * CREATED BY: EN 9/13/01
    * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 9/29/03 - issue 20054 return ending month of pay period
    *
    * Usage:
    *	Returns open/close status and begin month of a given pay
    *  period.
    *
    * Input params:
    *	@prco		PR company
    *	@prgroup 	PR Group
    * 	@prenddate  Period Ending date
    *
    * Output params:
    *  @status     0 if period is open, 1 if closed
    *  @beginmth   begin month of period
    *	@endmth		end month of period ** issue 20054
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @status tinyint output,
    @beginmth bDate output, @endmth bDate output, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
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
   	begin
   	select @msg = 'Missing PR Period Ending Date.', @rcode = 1
   	goto bspexit
   	end
   
   -- read info from PRPC
   select @status = Status, @beginmth = BeginMth, @endmth = EndMth from PRPC --issue 20054 get endmth for return parameter
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
       begin
       select @msg = 'Invalid pay period!', @rcode = 1
       goto bspexit
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPeriodStatusGet] TO [public]
GO
