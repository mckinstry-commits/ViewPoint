SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRResourceVal]
/*************************************
* validates HR Resources
*  Modified:
*				RM 02/27/01 - 	Took out code that caused no validation if value was numeric
*				MH 4/12/01 - 	Reversed above change.  If HRRef did not exist, @RefOut is set
*					to @HRRef to be treated as a new HRRef.	
*				allenn 3/6/2002 - issue 16164.  added output for the current Position code
*				mh 3/28/03 - middle name is not a required field.  can be null.  need to encapsulate
*					in an isnull() function and return an empty string if null.  Otherwise, the 
*					the entire message string will be returned as null.
*				mh 6/9/04 - 24736 Arithmetic Overflow error
*				TJL 10/28/08 - Issue #130622, Auto sequence next HRRef number.
*				mh 10/31/2008 - Issue #130144 - Build name like PR for return @msg
*				CHS 05/02/2011	- #142056 changed reference from HRRM to bHRRM
*
* Pass:
*   HRCo - Human Resources Company
*   HRRef - Resource ID to be Validated
*   
*
* Success returns:
*   Concatinated:  LastName, FirstName, MiddleName
*
* Error returns:
*	1 and error message
**************************************/
	(@HRCo bCompany = null, @HRRef varchar(15), @RefOut int output, @position varchar(10) output, @msg varchar(150) output)
	as
	set nocount on

	declare @rcode int, @lastname varchar(30), @firstname varchar(30), @middlename varchar(15), @suffix varchar(4)

	select @rcode = 0
   
	if @HRCo is null
	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
	if @HRRef is null
   	begin
   		select @msg = 'Missing HR Resource Number', @rcode = 1
   		goto bspexit
   	end
   
	/* Auto Numbering for new HRRef */
	if substring(@HRRef,1,1) = char(39) and substring(@HRRef,2,1) = '+'		--'+
	begin	
		if len(convert(varchar, (select isnull(Max(HRRef), 0) + 1 from bHRRM with (nolock) where HRCo = @HRCo))) > 6 -- #142056
		begin
			select @msg = 'Next HR Resource value exceeds the maximum value allowed for this input.'
			select @msg = @msg +'  You must enter a specific HR Resource value less than 999999.', @rcode = 1

			goto bspexit
		end
	else
		begin
			select @RefOut = isnull(Max(HRRef), 0) + 1
			from bHRRM with (nolock) -- #142056
			where HRCo = @HRCo

			goto bspexit
		end
	
	end
   
   
	--if isnumeric(@HRRef) = 1 
	--24736 Added call to function and check for len @HRRef
	if dbo.bfIsInteger(@HRRef) = 1
   	begin
		if len(@HRRef) < 7
   		begin
--	  		select @msg = isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), @RefOut = HRRef,@position = PositionCode
--	  		from HRRM 
--	  		where HRCo = @HRCo and HRRef = convert(int,@HRRef)

			select @lastname = LastName, @firstname = FirstName, @middlename = MiddleName,
			@suffix = Suffix, @RefOut = HRRef,@position = PositionCode
   			from HRRM 
   			where HRCo = @HRCo and HRRef = convert(int,@HRRef)

   		end
		else
   		begin
   			select @msg = 'Invalid HR Resource Number, length must be 6 digits or less.', @rcode = 1
   			goto bspexit
   		end
   	end
   	
	/* If not found, try to find as Sort Name */
	if @@rowcount = 0
	begin
		/*
		select @msg = LastName+', '+FirstName+', '+MiddleName, @RefOut = HRRef,@position = PositionCode
  		from HRRM 
		where HRCo = @HRCo and SortName = @HRRef
		*/

--		select @msg = isnull(LastName, '') + ', ' + 
--		isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), 
--		@RefOut = HRRef,@position = PositionCode
--  		from HRRM 
--		where HRCo = @HRCo and SortName = @HRRef

		select @lastname = LastName, @firstname = FirstName, @middlename = MiddleName,
		@suffix = Suffix, @RefOut = HRRef,@position = PositionCode
  		from HRRM 
		where HRCo = @HRCo and SortName = @HRRef

		/* If not found, try to find closest */
		if @@rowcount = 0
   		begin
--   			select @msg = isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), @RefOut = HRRef,@position = PositionCode
--   			from HRRM
--   			where HRCo = @HRCo and SortName like @HRRef + '%'

			select @lastname = LastName, @firstname = FirstName, @middlename = MiddleName,
			@suffix = Suffix, @RefOut = HRRef,@position = PositionCode
  			from HRRM 
			where HRCo = @HRCo and SortName like @HRRef + '%'


			/*
   			if @@rowcount = 0
   			begin
   				select @msg = 'Not a valid HR Resource Number', @rcode = 1
   				goto bspexit
   				end
   			end
			*/

			if @@rowcount = 0 -- then we have a new HRRef
			begin
				--04/12/01, reinstating code.  If HRRef is not found we need to return it as @RefOut for
				--switch-a-roo.  mh
				if dbo.bfIsInteger(@HRRef) = 1
				begin
   					--If the following line changes check bspHRAccDetailResVal.  mh 4/26/01
					select @RefOut = convert(int,convert(float, @HRRef)), @msg = ''
				end
				else
				begin
					select @msg = 'Not a valid HR Resource Number.', @rcode = 1
					goto bspexit
				end
			end
   		end
	end
   			
bspexit:

	if @rcode = 0
	begin
		if @suffix is null 
			select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
		else
			select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResourceVal] TO [public]
GO
