SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRPREmplVal    Script Date: 2/4/2003 7:42:41 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRPREmplVal    Script Date: 8/28/99 9:33:19 AM ******/
   CREATE   proc [dbo].[bspHRPREmplVal]
   
   /***********************************************************
    * CREATED BY: kb
    * MODIFIED By : EN 1/21/98
    *
    *
    * Usage:
   
    *	Used by most Employee inputs to validate the entry by either Sort Name or number.
    *
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *	@activeopt	Controls validation based on Active flag
    *			'Y' = must be an active
    *			'N' = must be inactive
    *			'X' = can be any value
    *
    * Output params:
    *	@emplout	Employee number
    *	@sortname	Sort Name
    *	@lastname	Last Name
    *	@firstname	First Name
    *	@msg		Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   (@prco bCompany, @empl varchar(15), @activeopt varchar(1), @emplout bEmployee=null output,
   @sortname bSortName=null output, @lastname varchar(30)=null output, @firstname varchar(30)=null output,
   @inscode bInsCode=null output, @dept bDept=null output, @craft bCraft=null output,
   @class bClass=null output, @jcco bCompany=null output, @job bJob=null output, @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @middlename varchar(15), @active bYN
   
   select @rcode = 0
   
   /* check required input params */
   
   if @empl is null
   	begin
   	select @msg = 'Missing Employee.', @rcode = 1
   	goto bspexit
   	end
   if @activeopt is null
   	begin
   	select @msg = 'Missing Active option for Employee validation.', @rcode = 1
   	goto bspexit
   	end
   
   /* If @empl is numeric then try to find Employee number */
   if isnumeric(@empl) = 1
   	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @inscode=InsCode,
   		@dept=PRDept, @craft=Craft, @class=Class, @jcco=JCCo, @job=Job
   	from PREH
   	where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   
   /* if not numeric or not found try to find as Sort Name */
   if @@rowcount = 0
   	begin
       	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @inscode=InsCode,
   		@dept=PRDept, @craft=Craft, @class=Class, @jcco=JCCo, @job=Job
   	from PREH
   	where PRCo=@prco and SortName = @empl
   
   	 /* if not found,  try to find closest */
      	if @@rowcount = 0
          		begin
           	set rowcount 1
           	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @inscode=InsCode,
   			@dept=PRDept, @craft=Craft, @class=Class, @jcco=JCCo, @job=Job
   		 from PREH
   			where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
    	  		begin
   	    		select @msg = 'Not a valid Employee', @rcode = 1
   			goto bspexit
   	   		end
   		end
   	end
   
   if @activeopt <> 'X' and @active <> @activeopt
   	begin
   	if @activeopt = 'Y' select @msg = 'Must be an active Employee.', @rcode = 1
   	if @activeopt = 'N' select @msg = 'Must be an inactive Employee.', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg=isnull(@lastname,'') + ', ' + isnull(@firstname, '') + ' ' + isnull(@middlename, '')
   
   
   bspexit:
       if @rcode <> 0 select @emplout =convert(int,convert(float, @empl))
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPREmplVal] TO [public]
GO
