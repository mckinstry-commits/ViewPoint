SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE       proc [dbo].[bspPRCanadianSINValidation]
   /***********************************************************
    * CREATED BY	: MCP 10/21/2010
    * MODIFIED BY	
    *				
    *				
    * USAGE:
    *	1. Checks an Employee's SIN# for uniqueness. 
    *	2. Runs the number through the Luhn's Algorithm to ensure it is valide
    *
    * INPUT PARAMETERS
    * 	 @prco      	PR Company
    *	 @empl      	Employee
    *	 @sin 			SIN#
    * 
    * OUTPUT PARAMETERS
    *    @msg      		error message 
    *
    * RETURN VALUE
    *  	 0         		success
    *    1        		failure
    *******************************************************************/ 
   
	(@prco bCompany = 0,@empl bEmployee, @sin varchar(11), @msg varchar(250) output )
   
	as

	set nocount on

	declare @rcode int, @count int, @country char(2)

	select @count = 0, @rcode = 0

	-- Ensure the SIN is unique
	select @count = count(SIN) from dbo.bPRCAEmployees with (nolock) where PRCo = @prco and SIN = @sin and Employee <> @empl
	if @count > 0
	begin
	   select @msg='Social Insurance # ' + @sin + ' already used by Employee# ' + convert(varchar(10), Employee) 
	   from dbo.bPRCAEmployees with (nolock) where PRCo=@prco and SIN=@sin and Employee<>@empl
	   select @rcode = 1
	   goto bspexit
	end
	
	select @country = Country from dbo.HQCO where HQCo = @prco
	if @country = 'CA'
	begin
		--Ensure the SIN is valide
		select @rcode = dbo.vfLuhnIsValid (LTRIM(RTRIM(@sin)))
		if @rcode > 0
		begin
			select @msg= @sin + ' is not a valid Social Insurance Number.'
		end
	end	
	
   bspexit:
   
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRCanadianSINValidation] TO [public]
GO
