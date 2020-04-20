SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplValwithGroup    Script Date: 8/28/99 9:33:19 AM ******/
   CREATE       proc [dbo].[bspPREmplValwithGroup]
   (@prco bCompany, @empl varchar(15),@activeopt varchar(1),
   	@prgroup bGroup,@emplout bEmployee=null output, 
   	@sortname bSortName= null output,@lastname varchar(30)= null output, 
   	@firstname varchar(30) = null output,@msg varchar(60) = null output)
   /***********************************************************
    * CREATED BY: kb
    * MODIFIED By : kb 1/24/98
    * MODIFIED By : kb 1/24/98
    *				GG 04/09/02 - added suffix to Employee name
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/07/02 - issue 19102  @msg name construct is null if PREH_MidName is null
    *				mh 6/11/04 - issue 24734
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
    *			'X' = can be any value
    *	@prgroup	PR Group
    *
    * Output params:
    *	@emplout	Employee number
    *	@sortname	Sort Name  *	@lastname	Last Name
    *	@firstname	First Name
    *	@msg		Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    **************************************************************************/ 
   as
   set nocount on
   declare @rcode int, @middlename varchar(15), @active bYN, @empgroup bGroup, @suffix varchar(4)
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
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
   if dbo.bfIsInteger(@empl) = 1
   begin
   	if len(@empl) < 7
   	begin
   		select @emplout = Employee, @sortname=SortName, @lastname=LastName, 
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
   			@empgroup=PRGroup, @suffix = Suffix
   		from PREH
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
   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
   		@empgroup=PRGroup, @suffix = Suffix
   	from PREH 	where PRCo=@prco and SortName = @empl
      	 	 /* if not found,  try to find closest */
      	if @@rowcount = 0
          		begin
           	set rowcount 1
           	select @emplout = Employee, @sortname=SortName, @lastname=LastName, 
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
   			@empgroup=PRGroup, @suffix = Suffix
   		 from PREH
   			where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
    	  		begin
   	    		select @msg = 'Not a valid Employee', @rcode = 1
   			goto bspexit
   	   		end
   		end
   	end
   if @empgroup<>@prgroup
   	begin
    	select @msg = 'Employee must be assigned to PR Group ' + convert(char(3),@prgroup), @rcode=1
   	goto bspexit
   	end
   
   if @activeopt <> 'X' and @active <> @activeopt
   	begin
   	select @msg = 'Must be an active Employee.' , @rcode = 1
   	goto bspexit
   	end
   
   if @suffix is null select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is not null select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   bspexit:
   	select @sortname = isnull(@sortname,convert(varchar(10),0)), @lastname = isnull(@lastname,convert(varchar(30),0)), 
   		@firstname = isnull(@firstname,convert(varchar(30),0))
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplValwithGroup] TO [public]
GO
