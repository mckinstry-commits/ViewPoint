SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPREmplValEmplMaster    Script Date: 8/28/99 9:33:19 AM ******/
CREATE       proc [dbo].[vspPREmplValEmplMaster]

/***********************************************************
* CREATED BY:	kb
* MODIFIED By:	kb 11/24/97
* MODIFIED By:	EN 1/21/98
*				EN 02/24/00 - changed to return message 'Not a Valid Employee' if vendor couldn't be found either by the vendor number or sort name (was inadvertantly giving a confusing datatype conversion error)
*				GG 04/09/02 - add suffix to Employee name
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 11/07/02 - issue 19102 @msg name is null if First or Middle Name is null
*				mh 6/11/04 - issue 24734
*				mh 3/24/05 - issue 23339 - added @autoearnexistyn output parameter
*				EN 7/17/06 - issue 27801 - added output params for @fsexistyn, @emplexistsinhr, and HRCO update flags
*				EN 3/25/08  #127592  improved the code that gets @fsexistyn
*				TJL 10/28/08 - Issue #130622, Auto sequence next Employee number.
*				CHS 05/02/2011	- #142056 changed reference from PREH to bPREH
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
*
* Output params:
*	@emplout	Employee number
*	@sortname	Sort Name

*	@lastname	Last Name
*	@firstname	First Name
*	@autoearnexistyn	= 'Y' if PRAE entries exist
*	@fsexistyn			= 'Y' if any filing status entries exist in PRED
*	@emplexistsinhr		= 'Y' if employee exists in HR
*	@updatenameyn		HRCO update flag 
*	@updateaddressyn	HRCO update flag
*	@updatehiredateyn	HRCO update flag
*	@updateactiveyn		HRCO update flag
*	@updatetimecardyn	HRCO update flag
*	@updatew4yn			HRCO update flag
*	@updateoccupyn		HRCO update flag
*	@updatessnyn		HRCO update flag    
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
   @autoearnexistyn bYN = 'N' output,
   @fsexistyn bYN = 'N' output,
   @emplexistsinhr bYN = 'N' output,
   @updatenameyn bYN = 'N' output, 
   @updateaddressyn bYN = 'N' output, 
   @updatehiredateyn bYN = 'N' output, 
   @updateactiveyn bYN = 'N' output,
   @updatetimecardyn bYN = 'N' output, 
   @updatew4yn bYN = 'N' output, 
   @updateoccupyn bYN = 'N' output, 
   @updatessnyn bYN = 'N' output,
   @msg varchar(150) output)
   
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

/* Auto Numbering for new Employees */
if substring(@empl,1,1) = char(39) and  substring(@empl,2,1) = '+'		--'+
	begin	
	if len(convert(varchar, (select isnull(Max(Employee), 0) + 1
		from bPREH with (nolock) where PRCo=@prco))) > 6	-- #142056
		begin
		select @msg = 'Next Employee value exceeds the maximum value allowed for this input.'
		select @msg = @msg +'  You must enter a specific Employee value less than 999999.', @rcode = 1
		goto bspexit
		end
	else
		begin
		select @emplout = isnull(Max(Employee), 0) + 1
		from bPREH with (nolock) -- #142056
		where PRCo=@prco
		goto FinishVal
		end
	end
   
   /* If @empl is numeric then try to find Employee number */
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
   if dbo.bfIsInteger(@empl) = 1
   begin
   	if len(@empl) < 7
   	begin
   		select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
   		from PREH with (nolock)
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
   	@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
   	from PREH with (nolock)
   	where PRCo=@prco and SortName = @empl
   
   	 /* if not found,  try to find closest */
      	if @@rowcount = 0
          		begin
           	set rowcount 1
           	select @emplout = Employee, @sortname=SortName, @lastname=LastName,
   			@firstname=FirstName, @middlename=MidName, @active=ActiveYN, @suffix = Suffix
   		 from PREH with (nolock)
   			where PRCo= @prco and SortName like @empl + '%'
   		if @@rowcount = 0
	  		begin
			--if isnumeric(@empl) = 1
			if dbo.bfIsInteger(@empl) = 1
				begin
				select @emplout=convert(int,convert(float, @empl)), @msg=''
				end
			else
				begin
				select @msg = 'Not a valid Employee', @rcode = 1
				goto bspexit
				end
   			end
   		end
   	end

FinishVal:
   if @activeopt <> 'X' and @active <> @activeopt
   	begin
   	select @msg = 'Must be an active Employee.' , @rcode = 1
   	goto bspexit
   	end
   
   if @suffix is null select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is not null select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   --issue 23339
   if exists(select 1 from dbo.PRAE with (nolock) where PRCo = @prco and Employee = @emplout)
   	select @autoearnexistyn = 'Y'
   else
   	select @autoearnexistyn = 'N'
   
   --issue 27801
   if exists(select 1 from dbo.PRED e with (nolock) 
			join dbo.PRDL d with (nolock) on e.PRCo=d.PRCo and e.DLCode=d.DLCode
			where e.PRCo = @prco and e.Employee = @emplout and d.DLType='D' and d.Method='R')
   	select @fsexistyn = 'Y'
   else
   	select @fsexistyn = 'N'

   --issue 27801
   select @updatenameyn = 'N', @updateaddressyn = 'N', @updatehiredateyn = 'N', @updateactiveyn = 'N'
   select @updatetimecardyn = 'N', @updatew4yn = 'N', @updateoccupyn = 'N', @updatessnyn = 'N'

   select @updatenameyn = HRCO.UpdateNameYN, @updateaddressyn = HRCO.UpdateAddressYN, 
	@updatehiredateyn = HRCO.UpdateHireDateYN, @updateactiveyn = HRCO.UpdateActiveYN,
   	@updatetimecardyn = HRCO.UpdateTimecardYN, @updatew4yn = HRCO.UpdateW4YN,
   	@updateoccupyn = HRCO.UpdateOccupCatYN, @updatessnyn = HRCO.UpdateSSNYN
   from dbo.HRCO with (nolock) 
   join dbo.HRRM with (nolock) on HRCO.HRCo = HRRM.HRCo
   where HRRM.PRCo = @prco and HRRM.PREmp = @emplout

   --issue 27801
   if exists (select 1 from dbo.HRRM with (nolock) where PRCo = @prco and PREmp = @emplout)
	select @emplexistsinhr = 'Y'
   else
	select @emplexistsinhr = 'N'


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREmplValEmplMaster] TO [public]
GO
