SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHRPREmpValUnique]
     
/***********************************************************
* CREATED BY: MH 11/6/00
* MODIFIED BY: MV 04/20/01 - Issue #13131 rewrote sp to:
*                              1) validate employee number
*                              2) check if HRRef already used by anther employee number
*                              3) return PR sortname
*				MH 5/14/01 - Issue 13415.  See comments below
			mh 3/26/03 - Issue 20850  Corrected val for new employee not in PR
*				mh 4/30/03 - Issue 19538 If PR Empl found, default PR info
*				mh 7/3/03 - Issue 21688 If PR Company is null get it from HRCO
*				mh 2/24/05 - Issue 27237 - Added ExistsInPR output parameter
*				mh 9/24/07 - Issue 29630 - Add Shift output param.
*				mh 6/4/2008 - 127577 - Added output paramters for cross update fields.
*				TJL 03/09/10 - Issue #135490, Add Office TaxState & Office LocalCode to HR Resource Master
*
* Usage:
*
*  Basically the same as bspHRPREmpVal except it will check for prior
*	existance of PREmployee in HRRM.
*
*
* Input params:
*	@prco		PR company
*  @hrref      HR Ref
*	@empl		Employee sort name or number
*	@activeopt	Controls validation based on Active flag
*			'Y' = must be an active
*			'N' = must be inactive
*			'X' = can be any value
*
* Output params:
*	@emplout	Employee number
*	@msg		Employee Name or error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/

--Issue #135490 - Added @wotaxstate varchar(4), @wolocalcode bLocalCode
(@hrco bCompany, @prco bCompany, @hrref bHRRef, @empl varchar(15), @emplout bEmployee=null output,
   	@ssn char(11), 
   	@firstname varchar(30), @lastname varchar(30), @midname varchar(15),
   	@prgroup bGroup output, @dept bDept output, 
   	@craft bCraft output, @class bClass output, @inscode bInsCode output, @taxstate bState output, 
   	@unempstate bState output, @insstate bState output, @localcode bLocalCode output, 
   	@earncode bEDLCode output, @prssn char(11) = null output, @existsinpr bYN = 'N' output, 
   	@autoearnexistyn bYN = 'N' output, @shift tinyint output, 
	@birthdate bDate output, @race char(1) output, @gender char(1) output, @suffix varchar(4) output,
	@address varchar(60) output, @city varchar(30) output, @state varchar(4) output, @zip bZip output,
	@address2 varchar(60) output, @phone bPhone output, @email varchar(50) output, @country char(2) output,
	@wotaxstate varchar(4) output, @wolocalcode bLocalCode output, @msg varchar(250) output)
   
 as
 set nocount on
 declare @sortname bSortName, @hrcount int,@hrrefcheck int, @rcode int, 
   	@prfirstname varchar(30), @prlastname varchar(30), @prmidname varchar(15), @msgbod1 varchar(15),
   	@msgbod2 varchar(15), @msgbod3 varchar(15), @msgbod4 varchar(15), @errhdr varchar(250)
     
SELECT @rcode = 0, @existsinpr = 'N', @autoearnexistyn = 'N'

if @hrco is null
	begin
	select @msg = 'Missing HRCo', @rcode = 1
	goto bsperr
	end

if not exists(select 1 from HRCO where HRCo = @hrco)
	begin
	select @msg = 'Invalid HR Company', @rcode = 1
	goto bsperr
	end

if @prco is null
	select @prco = PRCo from HRCO where HRCo = @hrco
   	
   
 -- First, validate the employee number.
 -- If @empl is numeric then try to find Employee number
IF isnumeric(@empl) = 1
	begin
	if not exists (select Employee from PREH where PRCo = @prco and Employee = convert(int,convert(float, @empl)))
		begin
		if exists (select Employee from bPREH where PRCo = @prco and Employee = convert(int,convert(float, @empl)))
			begin
			select @msg = 'Employee exists.  You do not have access to this record.' 
			select @rcode = 1
			goto bspexit
			end
		end
	   
	--Employee exists, get the output	
	--Issue #135490 - Added @wotaxstate, @wolocalcode
	select @emplout = Employee, @sortname=SortName, @prfirstname = FirstName, 
		@prlastname = LastName, @prmidname = MidName, @prgroup = PRGroup, @dept = PRDept, 
		@craft = Craft, @class = Class, @inscode = InsCode, @taxstate = TaxState,
		@unempstate = UnempState, @insstate = InsState, @localcode = LocalCode,
		@earncode = EarnCode, @prssn = SSN, @existsinpr = 'Y', @shift = Shift,
		@birthdate = BirthDate, @race = Race, @gender = Sex, @suffix = Suffix,
		@address = [Address], @city = City, @state = [State], @zip =Zip,
		@address2 = Address2, @phone = Phone, @email = Email, @country = Country,
		@wotaxstate = WOTaxState, @wolocalcode = WOLocalCode
	FROM PREH
	WHERE PRCo=@prco and Employee= convert(int,convert(float, @empl))
	end
     
-- if not numeric or not found try to find as Sort Name
IF @@rowcount = 0
 	BEGIN
	if not exists (select Employee from PREH where PRCo = @prco and SortName = @empl)
		begin
		if exists (select Employee from bPREH where PRCo = @prco and SortName = @empl)
			begin
			select @msg = 'Employee exists.  You do not have access to this record.'
			select @rcode = 1
			goto bspexit
			end
		end

	--Employee exists, get the output
	--Issue #135490 - Added @wotaxstate, @wolocalcode
	select @emplout = Employee, @sortname=SortName, @prfirstname = FirstName, 
		@prlastname = LastName, @prmidname = MidName, @prgroup = PRGroup, @dept = PRDept, 
		@craft = Craft, @class = Class, @inscode = InsCode, @taxstate = TaxState,
		@unempstate = UnempState, @insstate = InsState, @localcode = LocalCode,
		@earncode = EarnCode, @prssn = SSN, @existsinpr = 'Y',
		@birthdate = BirthDate, @race = Race, @gender = Sex, @suffix = Suffix,
		@address = [Address], @city = City, @state = [State], @zip =Zip,
		@address2 = Address2, @phone = Phone, @email = Email, @country = Country,
		@wotaxstate = WOTaxState, @wolocalcode = WOLocalCode
	FROM PREH
	WHERE PRCo=@prco and SortName = @empl
     
	-- if not found,  try to find closest
	IF @@rowcount = 0
		BEGIN
		set rowcount 1
		if not exists (select Employee from PREH where PRCo= @prco and SortName like @empl + '%')
			begin
			if exists (select Employee from bPREH where PRCo= @prco and SortName like @empl + '%')
				begin
				select @msg = 'Employee exists.  You do not have access to this record.'
				select @rcode = 1
				goto bspexit
				end
			end
   
		--Employee exists, get the output
		--Issue #135490 - Added @wotaxstate, @wolocalcode
		SET rowcount 1
		select @emplout = Employee, @sortname=SortName, @prfirstname = FirstName, 
			@prlastname = LastName, @prmidname = MidName, @prgroup = PRGroup, @dept = PRDept, 
			@craft = Craft, @class = Class, @inscode = InsCode, @taxstate = TaxState,
			@unempstate = UnempState, @insstate = InsState, @localcode = LocalCode,
			@earncode = EarnCode, @prssn = SSN, @existsinpr = 'Y',
			@birthdate = BirthDate, @race = Race, @gender = Sex, @suffix = Suffix,
			@address = [Address], @city = City, @state = [State], @zip =Zip,
			@address2 = Address2, @phone = Phone, @email = Email, @country = Country,
			@wotaxstate = WOTaxState, @wolocalcode = WOLocalCode
 		FROM PREH
 		WHERE PRCo= @prco and SortName like @empl + '%'
     
   		IF @@rowcount = 0
   			BEGIN
   			if isnumeric(@empl) = 1
   				begin
				--this is a new employee to bPREH.  do we want to do the remaining checks?
				select @emplout = convert(int,convert(float, @empl)), @msg = ''
				goto bspexit
   				end
   			else
   				begin
				select @msg = 'Not a valid PR Employee Number', @rcode = 1
				goto bspexit
   				end
   			END
   		END
   	END
   	
-- If the employee number is valid then test to see if it already exists in HRRM
SELECT @hrcount = count(*) FROM HRRM m JOIN HRCO o on m.HRCo = o.HRCo and m.PRCo = o.PRCo
WHERE m.HRCo = @hrco and m.PRCo = @prco and m.PREmp = @emplout
     
IF @hrcount = 1
   	BEGIN
	SELECT @hrrefcheck = (select HRRef from HRRM where HRCo = @hrco and PRCo = @prco
     					and PREmp = @emplout)
	IF @hrrefcheck <> @hrref
   		BEGIN
   		SELECT @msg = 'PR Employee already assigned to HRRef ' + convert(varchar(10), @hrrefcheck), @rcode = 1
   		goto bspexit
   		END
   	END
     
IF @hrcount > 1
   	BEGIN
	SELECT @msg = 'PR Employee used in HRRM by more then one HRRef', @rcode = 1
	goto bspexit
   	END

--Employee exists in HR.  Make sure Names and SSN match.
select @errhdr = 'HR Ref does not match PR Emp - '

if @prfirstname <> @firstname
   	begin
	select @errhdr = @errhdr + ' First name,', @rcode = 1
   	end
   
if @prmidname <> @midname
   	begin
	select @errhdr = @errhdr + ' Middle name,', @rcode = 1
   	end
   
 if @prlastname <> @lastname
   	begin
	select @errhdr = @errhdr + ' Last name,', @rcode = 1
   	end
   
--If a SSN is supplied, it needs to be validated.  Otherwise default it from PR.
if @ssn is not null
   	begin
	if @prssn <> @ssn
   		begin
		--select @errhdr = @errhdr + ' SSN,' + ' ' + @prssn, @rcode = 1
		select @errhdr = @errhdr + ' SSN ', @rcode = 1
		select @prssn = null
   		end
   	end
   
if @rcode = 1
   	begin
	select @ssn = null, @firstname = null, @lastname = null, @midname = null,
	@prgroup  = null, @dept = null, @craft = null, 
	@class = null, @inscode = null, @taxstate = null, 
	@unempstate = null, @insstate = null, @localcode = null, 
	@earncode = null,
	@birthdate = null, @race = null, @gender = null, @suffix = null,
	@address = null, @city = null, @state = null, @zip =null,
	@address2 = null, @phone = null, @email = null, @country = null,
	@wotaxstate = null, @wolocalcode = null

	--select @msg = substring(@errhdr, 1, len(@errhdr) - 1)
	select @msg = @errhdr
	goto bspexit
   	end
   
-- If all tests are passed, return sortname
SELECT @msg = @sortname

--issue 23339
if exists(select 1 from dbo.PRAE where PRCo = @prco and Employee = @emplout)
	select @autoearnexistyn = 'Y'
else
	select @autoearnexistyn = 'N'

bspexit:
	if @rcode <> 0  and isnumeric(@empl) = 1 
		select @emplout =convert(int,convert(float, @empl))
   
bsperr:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRPREmpValUnique] TO [public]
GO
