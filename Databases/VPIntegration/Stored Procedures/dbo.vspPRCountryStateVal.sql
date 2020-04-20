SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCountryStateVal]	
	/******************************************************
	* CREATED BY:	mh 3/3/2008 
	* MODIFIED By:  MV 3/12/08 - isnull wrapped @country, @state for errmsg
	*
	* Usage:	Validates State and returns country from HQCO default specification.  
	*	
	*
	* Input params:
	*	
	*			@hqco, @state
	*
	* Output params:
	*	@country	HQCO default country
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hqco bCompany, @state varchar(4), @country char(2) output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	select @country = DefaultCountry from dbo.HQCO (nolock) where HQCo = @hqco
	if @country is null 
	begin
		select @rcode = 1, @msg = 'Country not set in HQ'
	end
	

	exec @rcode = vspHQCountryVal @country, @msg output
	if @rcode = 0
	begin
		if exists(select 1 from dbo.HQST (nolock) where Country = @country and [State] = @state)
		begin
			select @msg = [Name] from dbo.HQST (nolock) where Country = @country and [State] = @state
		end
		else
		begin	
			select @msg = 'Country "' + isnull(@country,'') + '" and State "' + isnull(@state,'') + '" not set up in HQ States', @rcode = 1
		end
	end
		--let failures from vspHQCountryVal flow back to calling routine.

	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCountryStateVal] TO [public]
GO
