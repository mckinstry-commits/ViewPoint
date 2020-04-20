SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplValUnempl    Script Date: 8/28/99 9:33:19 AM ******/
   CREATE      proc [dbo].[bspPREmplValUnempl]
   
   /***********************************************************
    * CREATED BY: danf 08/31/00
    * MODIFIED By : GF 04/03/02 - Added suffix to output params
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/07/02 - issue 19102 @msg name is null if First or Middle Name is null
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
   (@prco bCompany,
   @empl varchar(15),
   @activeopt varchar(1),
   @emplout bEmployee=null output,
   @sortname bSortName=null output,
   @lastname varchar(30)=null output,
   @firstname varchar(30)=null output,
   @middlename varchar(15)=null output,
   @ssnumber varchar(11)=null output,
   @hiredate bDate=null output,
   @termdate bDate=null output,
   @suffix varchar(4)=null output,
   @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @active bYN
   
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
   
   -- If @empl is numeric then try to find Employee number
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
   if dbo.bfIsInteger(@empl) = 1
   begin
   	if len(@empl) < 7
   	begin
   		select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @ssnumber=SSN,
   			@hiredate=HireDate, @termdate=TermDate, @suffix=Suffix
   		from PREH
   		where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   	end
   	else
   	begin
   		select @msg = 'Invalid Employee Number, length must be 6 digits or less.', @rcode = 1
   		goto bspexit
   	end
   end
   
   -- if not numeric or not found try to find as Sort Name 
   if @@rowcount = 0
   	begin
       	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @ssnumber=SSN,
   		@hiredate=HireDate, @termdate=TermDate, @suffix=Suffix
   	from PREH
   	where PRCo=@prco and SortName = @empl
   
   	 /* if not found,  try to find closest */
      	if @@rowcount = 0
          		begin
           	set rowcount 1
           	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @ssnumber=SSN,
   		    @hiredate=HireDate, @termdate=TermDate, @suffix=Suffix
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
   
   
   if @suffix is null select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is not null select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplValUnempl] TO [public]
GO
