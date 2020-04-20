SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSEmplPRGroupVal    Script Date: 8/28/99 9:35:39 AM ******/
   CREATE              proc [dbo].[bspPRTSEmplPRGroupVal]
   /****************************************************************************
    * CREATED BY: EN 4/9/04
    * MODIFIED By :	EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
    *
    * USAGE:
    * Validats whether employees are still all assigned the timesheet's PRGroup.
    * 
    *  INPUT PARAMETERS
    *   	@prco			PR Company
    *   	@crew			PR Crew
    *   	@postdate		Posting Date
    *		@sheet			Timesheet Sheet #
    *		@prgroup		PR Group assigned to timesheet
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************/ 
   (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
    @sheet smallint = null, @prgroup bGroup = null, @msg varchar(255) output)
   
   as
    
   set nocount on
     
   declare @rcode int, @reccount int
   
   select @rcode = 0
     
   -- validate PRCo
   if @prco is null
   	begin
   	select @msg = 'Missing PR Co#!', @rcode = 1
   	goto bspexit
   	end
   -- validate Crew
   if @crew is null
   	begin
   	select @msg = 'Missing Crew!', @rcode = 1
   	goto bspexit
   	end
   -- validate PostDate
   if @postdate is null
   	begin
   	select @msg = 'Missing Timecard Date!', @rcode = 1
     	goto bspexit
     	end
   -- validate Sheet number
   if @sheet is null
     	begin
     	select @msg = 'Missing Sheet #!', @rcode = 1
     	goto bspexit
     	end
   -- validate PR Group
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode=1
   	goto bspexit
   	end
   
   select @reccount = count(*) from dbo.PRRE a with (nolock)
   join dbo.PREH h with (nolock) on h.PRCo=a.PRCo and h.Employee=a.Employee
   where a.PRCo=@prco and a.Crew=@crew and a.PostDate=@postdate and a.SheetNum=@sheet and h.PRGroup<>@prgroup
   
   select @reccount = @reccount + count(*) from dbo.PRRQ a with (nolock)
   join dbo.PREH h with (nolock) on h.PRCo=a.PRCo and h.Employee=a.Employee
   where a.PRCo=@prco and a.Crew=@crew and a.PostDate=@postdate and a.SheetNum=@sheet and h.PRGroup<>@prgroup
   
   if @reccount > 0
   	begin
   	select @msg = 'One or more employees in this timesheet not assigned to PR Group ' + convert(varchar,@prgroup), @rcode=1
   	goto bspexit
   	end
   
     
   bspexit:
     	if @rcode <> 0 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRTSEmplPRGroupVal]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSEmplPRGroupVal] TO [public]
GO
