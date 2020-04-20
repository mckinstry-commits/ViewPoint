SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewGroupVal    Script Date: 11/5/2002 1:20:25 PM ******/
    /****** Object:  Stored Procedure dbo.bspPRCrewGroupVal    Script Date: 8/28/99 9:33:21 AM ******/
    CREATE    proc [dbo].[bspPRCrewGroupVal]
    /***********************************************************
     * CREATED BY: EN 2/25/03
     * MODIFIED By :
     *
     * USAGE:
     * Validates Crew PR Group in PRGR and also returns error if
     * not all employees assigned to crew are assigned to same
     * PR Group.
     *
     * INPUT PARAMETERS
     *   PRCo   PR Co to validate agains 
     *	 Crew	PR Crew for verifying that employee PR Groups all match Crew PR Group
     *   Group  PR Group to validate
     * OUTPUT PARAMETERS
     *	 @groupout assigned PR Group of all employees in crew
     *			    ... if not all employees are in same group, returns the group passed in to this procedure
     *   @msg      error message if error occurs otherwise Description of PR Group
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/ 
    
    (@prco bCompany = 0, @crew varchar(10) = null, @group bGroup = null, @groupout bGroup output,
     @msg varchar(60) output)
    as
    
    set nocount on
    
    declare @rcode int, @numrows int, @numgroups int
    
    select @rcode = 0
    
    if @prco is null
    	begin
    	select @msg = 'Missing PR Company!', @rcode = 1
    	goto bspexit
    	end
    
    if @crew is null
    	begin
    	select @msg = 'Missing Crew!', @rcode = 1
    	goto bspexit
    	end
    
    -- skip validation if crew's PR Group is null
    if @group is null
    	begin
    	goto bspexit
    	end
    
    --check for multiple pr groups within employees assigned to crew
    select @numgroups = (select count(distinct e.PRGroup) from PRCW w 
    					 join PREH e on w.PRCo=e.PRCo and w.Employee=e.Employee 
    					 where w.PRCo=@prco and w.Crew=@crew)
    if @numgroups > 1
    	begin
    	select @groupout = @group
    	select @msg = 'Employees must be assigned to same Group!', @rcode = 1
    	goto bspexit
    	end
    
    --return PR Group that employees are all assigned to
    select @groupout = (select distinct e.PRGroup from PRCW w 
    join PREH e on w.PRCo=e.PRCo and w.Employee=e.Employee 
    where w.PRCo=@prco and w.Crew=@crew)
   
    if @groupout is null select @groupout=@group
   
   /* if @groupout<>@group
   	begin
   	select @msg = 'Invalid Group!', @rcode = 1
   	goto bspexit
    	end*/
   
    --validate off of return PR Group
    select @msg = Description
    	from PRGR
    	where PRCo = @prco and PRGroup=@groupout
    if @@rowcount = 0
    	begin
    	select @msg = 'PR Group not on file!', @rcode = 1
    	goto bspexit
    	end
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewGroupVal] TO [public]
GO
