SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspPREmplValforCheckRepl]
   /***********************************************************
    * CREATED BY: GG 09/15/01
    * MODIFIED By: GG 04/09/02 - added suffix to Employee name
    *				EN 11/07/02 - issue 19102 @msg name is null if First or Middle Name is null
    *				mh 6/11/04 - issue 24734
    *
    * Usage:
    *	Called by the PR Check Replacement form to validate Employee.  Must be
    *	an Employee within this specific pay period
    *
    * Input params:
    *	@prco		PR company
    *	@prgroup	PR Group
    *	@prenddate	PR End Date
    *	@empl		Employee sort name or number
    *
    * Output params:
    *	@emplout	Employee number
    *	@msg		Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    **************************************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @empl varchar(15) = null, @emplout bEmployee output, @msg varchar(75) output)
   
   as
   set nocount on
   
   declare @rcode int, @lastname varchar(30),@firstname varchar(30),@middlename varchar(15),
   	@suffix varchar(4)
   
   select @rcode = 0
   
   -- check required input params
   if @empl is null
   	begin
   	select @msg = 'Missing Employee.', @rcode = 1
   	goto bspexit
   	end
   
   -- if value for Employee is numeric then try to find Employee number
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
   if dbo.bfIsInteger(@empl) = 1
   begin
   	if len(@empl) < 7
   	begin
   		select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, @suffix = Suffix
   		from PREH
   		where PRCo = @prco and Employee= convert(int,@empl)
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
       select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, @suffix = Suffix
   	from PREH
   	where PRCo = @prco and SortName = @empl
   -- if not found,  try to find closest match
   	if @@rowcount = 0
          	begin
           set rowcount 1
           select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, @suffix = Suffix
   		from PREH
   		where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
    	  		begin
   	    	select @msg = 'Not a valid Employee.', @rcode = 1
   			goto bspexit
   	   		end
   		end
   	end
   -- make sure this Employee exists within the Pay Period
   if (select count(*) from PRSQ where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and Employee = @emplout) = 0
   	begin
   	select @msg = 'Employee does not have a Sequence Control record within this Pay Period.', @rcode = 1
   	goto bspexit
   	end
   
   if @suffix is null select @msg = @lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is not null select @msg = @lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplValforCheckRepl] TO [public]
GO
