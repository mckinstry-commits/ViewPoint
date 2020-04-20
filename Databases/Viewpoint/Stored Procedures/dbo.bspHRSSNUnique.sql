SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRSSNUnique    Script Date: 2/4/2003 7:51:57 AM ******/

CREATE   proc [dbo].[bspHRSSNUnique]
/***********************************************************
* CREATED BY	:	ae 4/21/99
* MODIFIED BY	:	mh 10/17/00 - check for dup ssn in PR too (not this HR/Employee).
*					mh 8/7/03 - Issue 22077
*					MCP 10/22/10 - Issue #139552 If we are in Canada, we need to make sure the SIN is valid
*					AMR 01/12/11 - Issue #142350, removing the duplicate variable by reassigning the input var
*				CHS	09/26/2011	- B-06080 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000.						
* USAGE:
*	Checks an Employees SSN# for uniqueness. Called
*	from HR Resource Master maintenance form.

*
* INPUT PARAMETERS
* 	 @HRCo      	HR Company
*	 @HRRef      	Resource
*	 @SSN 		SSN#
*
* OUTPUT PARAMETERS
*   	@msg      	error message
*
* RETURN VALUE
*  	 0         		success
*   	1        		failure
*******************************************************************/   
(@HRCo bCompany = 0, @PRCo bCompany, @HRRef bHRRef, @SSN char(11), @msg varchar(80) output )
   as
   
   set nocount on
   
	DECLARE @rcode int,
			@count int,
			@hrfname varchar(30),
			@hrlname varchar(30),
			@prfname varchar(30),
			@prlname varchar(30),
			@premp bEmployee,
			@country char(2),
			@defaultcountry char(2)
   
   select @rcode = 0, @msg = 'HR Unique'
   
   --Issue 9930
   --begin old
   --select @rcode=1, @msg='Social Security # ' + @SSN + ' already used by resource # ' + convert(varchar(10), HRRef)
   --  from HRRM where HRCo=@HRCo and SSN=@SSN and HRRef<>@HRRef
   --end old
   
   if @PRCo is null
   begin
   	select @PRCo = PRCo from HRCO where HRCo = @HRCo
   	if @PRCo is null
   	begin
   		select @msg = 'PR Company must be defined in HR Company', @rcode = 1
   		goto bspexit
   	end
   end
   
	select @defaultcountry = DefaultCountry from dbo.HQCO where HQCo = @HRCo
	
   --Look in HR for dup SSN
   	IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @SSN NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
		BEGIN
		--Look in HR for dup SSN
		select @count = count(SSN) from HRRM where HRCo = @HRCo and SSN = @SSN and HRRef <> @HRRef
		   if @count > 0
			   begin
				   select @msg= @SSN + ' already used by Resource # ' + convert(varchar(10), HRRef)
				   from HRRM where HRCo=@HRCo and SSN=@SSN and HRRef<>@HRRef
				   select @rcode = 1
				   goto bspexit
			   end

		--Look in PR for dup SSN
		select @count = count(SSN) from PREH where PRCo = @PRCo and SSN = @SSN
		   if @count > 0
			   begin
				   select @hrfname = FirstName, @hrlname = LastName from HRRM where HRCo = @HRCo and HRRef = @HRRef

				   select @premp = Employee, @prfname = FirstName, @prlname = LastName from PREH where PRCo = @PRCo and SSN = @SSN

				   if @prfname <> @hrfname and @prlname <> @hrlname and @HRRef <> @premp
					   begin
						   select @msg = @SSN + ' already used in PR Employee by Employee ' + convert(varchar(10), @premp)
						   select @rcode = 1
						   goto bspexit
					   end
			   end		
		END
           	
	--Issue #139552 If we are in Canada, we need to make sure the SIN is valid
	select @country = Country from dbo.HQCO where HQCo = @HRCo
	
	if @country = 'CA'
	begin
		-- Remove all '-' from the SIN
		declare @sin varchar(100), @i int
		select @sin = @SSN
		select @sin
			select @i = patindex('%-%', @sin)
			while @i > 0
			begin
				select @sin = replace(@sin, substring(@sin, @i, 1), '')
				select @i = patindex('%-%', @sin)
			end
			
		--Ensure the SIN is valide
		select @rcode = dbo.vfLuhnIsValid (LTRIM(RTRIM(@sin)))
		if @rcode > 0
		begin
			select @msg= @SSN + ' is not a valid Social Insurance Number.'
			goto bspexit
		end
	end	
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRSSNUnique] TO [public]
GO
