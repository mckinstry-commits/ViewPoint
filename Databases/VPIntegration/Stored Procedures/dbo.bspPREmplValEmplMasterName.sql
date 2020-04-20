SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplValEmplMasterName    Script Date: 8/28/99 9:33:19 AM ******/
CREATE proc [dbo].[bspPREmplValEmplMasterName]
/***********************************************************
    * CREATED BY: danf 08/17/00
    * MODIFIED By : GG 04/09/02 - added suffix to Employee name
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/07/02 - issue 19102 @msg name is null if First or Middle Name is null
    *
    * Usage:
    *	Used by MS to by pass data security checks.
    *
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *	@activeopt	Controls validation based on Active flag
    *			'Y' = must be an active
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
   @sortname bSortName output,
   @lastname varchar(30) output,
   @firstname varchar(30) output,
   @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @middlename varchar(15), @active bYN, @suffix varchar(4)
   
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
if dbo.bfIsInteger(@empl) = 1
	begin
   	if len(@empl) < 7
		begin
   		select @emplout = Employee, @sortname=SortName, @lastname=LastName,
				@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
   		from PREHName
   		where PRCo=@prco and Employee= convert(int,convert(float, @empl))
		end
   	else
		begin
   		select @msg = 'Invalid Employee Number, length must be 6 digits or less.', @rcode = 1
   		goto bspexit
		end
	end

----   /* If @empl is numeric then try to find Employee number */
----   if isnumeric(@empl) = 1
----   	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
----   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
----   	from PREHName
----   	where PRCo=@prco and Employee= convert(int,convert(float, @empl))

/* if not numeric or not found try to find as Sort Name */
if @@rowcount = 0
	begin
	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
	from PREHName
   	where PRCo=@prco and SortName = @empl
	/* if not found,  try to find closest */
	if @@rowcount = 0
		begin
		set rowcount 1
		select @emplout = Employee, @sortname=SortName, @lastname=LastName,
                  @firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
		from PREHName
		where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
			begin
			-- if isnumeric(@empl) = 1
			--   select @emplout=convert(int,convert(float, @empl)), @msg=''
			-- else
			select @msg = 'Not a valid Employee', @rcode = 1
   			goto bspexit
			end
		end
	end

if @activeopt <> 'X' and @active <> @activeopt
   	begin
   	select @msg = 'Must be an active Employee.', @rcode = 1
   	goto bspexit
   	end


if @suffix is null select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
if @suffix is not null select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplValEmplMasterName] TO [public]
GO
