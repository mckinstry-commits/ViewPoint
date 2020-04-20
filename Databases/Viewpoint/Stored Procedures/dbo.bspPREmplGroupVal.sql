SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplGroupVal    Script Date: 8/28/99 9:33:18 AM ******/
   CREATE     proc [dbo].[bspPREmplGroupVal]
   
   /***********************************************************
    * CREATED BY: EN 5/25/98
    * MODIFIED By : EN 5/25/98
    *				GG 04/09/02 - added suffix to Employee name
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				mh 6/11/04 - issue 24734
    *
    *
    * Usage:
    *	Used to validate the entry by either Sort Name or number.
    *	Also verifies that employee is assigned to specified PR group.
    *
    * Input params:
    *	@prco		PR company
    *	@prgroup	PR Group
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
    *	@paymethod	Default Payment Method
    *	@msg		Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/ 
   (@prco bCompany, @prgroup bGroup, @empl varchar(15), @activeopt varchar(1),
    @emplout bEmployee=null output, @sortname bSortName output, @lastname varchar(30) output,
    @firstname varchar(30) output, @paymethod char(1) output, @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @middlename varchar(15), @active bYN, @grp bGroup, @suffix varchar(4)
   
   select @rcode = 0
   
   /* check required input params */	
   
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group.', @rcode = 1
   	goto bspexit
   	end
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
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
   if dbo.bfIsInteger(@empl) = 1
   begin
   	if len(@empl) < 7
   	begin
   		select @emplout = Employee, @sortname=SortName, @lastname=LastName, 
   			@firstname=FirstName, @middlename=MidName, @grp=PRGroup, @active=ActiveYN,
   			@paymethod=case when DirDeposit='A' then 'E' else 'C' end, @suffix = Suffix
   		from dbo.PREH with (nolock)
   		where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   	end
   	else
   	begin
   		select @msg = 'Invalid Employee Number, length must be 6 digits or less.', @rcode = 1
   		goto bspexit
   	end
   end
   
   /* if not numeric or not found try to find as Sort Name */
   if @@rowcount = 0
   	begin
       	select @emplout = Employee, @sortname=SortName, @lastname=LastName, 
   		@firstname=FirstName, @middlename=MidName, @grp=PRGroup, @active=ActiveYN,
   		@paymethod=case when DirDeposit='A' then 'E' else 'C' end, @suffix = Suffix
   	from dbo.PREH with (nolock)
   	where PRCo=@prco and SortName = @empl
      	
   	 /* if not found,  try to find closest */
      	if @@rowcount = 0
          		begin
           	set rowcount 1
           	select @emplout = Employee, @sortname=SortName, @lastname=LastName, 
   			@firstname=FirstName, @middlename=MidName, @grp=PRGroup, @active=ActiveYN,
   			@paymethod=case when DirDeposit='A' then 'E' else 'C' end, @suffix = Suffix
   		 from dbo.PREH with (nolock)
   			where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
    	  		begin
   	    		select @msg = 'Not a valid Employee', @rcode = 1
   			goto bspexit
   	   		end
   		end
   	end
   
   if @prgroup <> @grp
   	begin
   	select @msg = 'Employee is not assigned to this group.', @rcode = 1
   	goto bspexit
   	end
   	
   if @activeopt <> 'X' and @active <> @activeopt
   	begin
   	if @activeopt = 'Y' select @msg = 'Must be an active Employee.', @rcode = 1
   	if @activeopt = 'N' select @msg = 'Must be an inactive Employee.', @rcode = 1
   	goto bspexit
   	end
   
   if @suffix is not null select @msg = isnull(@lastname,'') + ' ' + @suffix +  ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is null select @msg=isnull(@lastname,'') + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplGroupVal] TO [public]
GO
