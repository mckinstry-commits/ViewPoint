SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSSNUnique    Script Date: 8/28/99 9:35:40 AM ******/
   CREATE       proc [dbo].[bspPRSSNUnique]
/***********************************************************
* CREATED BY:	kb	11/24/1997
* MODIFIED BY:	kb	11/24/1997
*				EN	10/09/2002	- issue 18877 change double quotes to single
*				mh	01/17/2005	- Issue 25746.  Corrected check against HR.  Was using HRCo = 1 in error.  Also was
*									making a comparison using HRCo = PRCo in error.  Corrected check against PR
*									to use table instead of view.
*				MCP 10/21/2010	- Issue #139552 If we are in Canada, we need to make sure the SIN is valid. Also made
*									the messages more generic
*				CHS	09/26/2011	- B-06080 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000.
*
* USAGE:
*	Checks an Employee's SSN# for uniqueness. Called
*	from PR Employee Header maintenance form. 
*
* INPUT PARAMETERS
* 	 @prco      	PR Company
*	 @empl      	Employee
*	 @ssn 		SSN#
* 
* OUTPUT PARAMETERS
*   	@msg      	error message 
*
* RETURN VALUE
*  	 0         		success
*   	1        		failure
*******************************************************************/ 
(@prco bCompany = 0,@empl bEmployee, @ssn char(11), @msg varchar(250) output )
   
	as

	set nocount on

	declare @rcode int, @count int, @hrref bHRRef, @hrco bCompany, @hrempl bEmployee, @country char(2), @defaultcountry char(2)

	select @count = 0, @rcode = 0

	select @defaultcountry = DefaultCountry from dbo.HQCO where HQCo = @prco
	
	IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @ssn NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
		BEGIN
		select @count = count(SSN) from dbo.bPREH with (nolock) where PRCo = @prco and SSN = @ssn and Employee <> @empl
		if @count > 0
			begin
			select @msg= @ssn + ' is already used by Employee# ' + convert(varchar(10), Employee) 
			from dbo.bPREH with (nolock) where PRCo=@prco and SSN=@ssn and Employee<>@empl
			select @rcode = 1
			goto bspexit
			end			

		--Issue 127996 - only check HR if it is active.
		if exists (select 1 from vDDMO where Mod = 'HR' and Active = 'Y')
			begin
				select top 1 @hrco = HRCo, @hrref = HRRef, @hrempl = PREmp
				from dbo.bHRRM with (nolock) where SSN = @ssn and PRCo = @prco and isnull(PREmp,-999) <> @empl
				if @@rowcount > 0

				begin
					select @msg = @ssn + ' is used in HR Resource Master by:' + char(13)  + 'HRCo - ' + convert(varchar, @hrco) +  ', Resource - ' + convert(varchar, @hrref) + ', Employee - ' + isnull(convert(varchar, @hrempl),'Not Specified'), @rcode = 1
					goto bspexit
				end
			end
		END			
	
	
	--Issue #139552 If we are in Canada, we need to make sure the SIN is valid
	select @country = Country from dbo.HQCO where HQCo = @prco
	
	if @country = 'CA'
	begin
		
		-- Remove all '-' from the SIN
		declare @sin varchar(100), @i int
		select @sin = @ssn
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
			select @msg= @ssn + ' is not a valid Social Insurance Number.'
		end
	end	
   
   bspexit:
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSSNUnique] TO [public]
GO
