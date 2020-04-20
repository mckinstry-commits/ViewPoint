SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQCountryVal]
	/******************************************************
	* CREATED BY:		mh 2/29/2008 
	* MODIFIED By:
	*
	* Usage:		validate Country code against HQCountry
	*	
	*
	* Input params:
	*	
	*				@country - two character country code
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@country char(2), @msg varchar(50) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @country is null
	begin
		select @msg = 'Missing Country code!', @rcode = 1
		goto vspexit	
	end

	if exists(select 1 from HQCountry where Country = @country)
	begin
		select @msg = CountryName from HQCountry where Country = @country
	end
	else
	begin
		select @msg = 'Country not set up in HQ Country', @rcode = 1
		goto vspexit
	end
	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCountryVal] TO [public]
GO
