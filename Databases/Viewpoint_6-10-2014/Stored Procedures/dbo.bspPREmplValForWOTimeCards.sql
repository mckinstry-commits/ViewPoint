SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplVal    Script Date: 8/28/99 9:33:19 AM ******/
CREATE proc [dbo].[bspPREmplValForWOTimeCards]

/***********************************************************
* CREATED BY: JM 7/12/02 - Adapted from bspPREmplVal to validate PREmpl and return EMFixedRate
*		for EMWOTimeCards form.
*
* MODIFIED By : EN 10/15/02 issue 18964  return error if @emfixerate return parameter = 0
*				EN 11/07/02 - issue 19102 @msg name is null if First or Middle Name is null
* 				DANF 03/15/04 - issue 23969 Allow users to post time in EM Time Cards.
*
* Usage:
*	Used by most Employee inputs to validate the entry by either Sort Name or number
*	and to return EMFixedRate.
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
*	@emfixedrate
*	@msg		Employee Name or error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
(@prco bCompany,
@empl varchar(15),
@activeopt varchar(1),
@emplout bEmployee=null output,
@emfixerate bUnitCost output,
@msg varchar(255) output)
   
as
set nocount on

declare @rcode int, @middlename varchar(15), @active bYN, @suffix varchar(4),
@sortname bSortName,
@lastname varchar(30),
@firstname varchar(30)
   
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
	@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
	@suffix = Suffix, @emfixerate = EMFixedRate
from PREHName
where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   
/* if not numeric or not found try to find as Sort Name */
if @@rowcount = 0
   	begin
	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   		@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
   		@suffix = Suffix, @emfixerate = EMFixedRate
   	from PREHName
   	where PRCo=@prco and SortName = @empl
   
   	 /* if not found,  try to find closest */
	if @@rowcount = 0
		begin
		set rowcount 1
		select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, 
   			@suffix = Suffix, @emfixerate = EMFixedRate
   		from PREHName
   		where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
    		begin
   			select @msg = 'Not a valid Employee.', @rcode = 1
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

if @emfixerate = 0 select @msg = 'Employee Fixed rate is missing.  Once repaired, Employee must be cleared and re-entered.', @rcode = 1

bspexit:
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplValForWOTimeCards] TO [public]
GO
