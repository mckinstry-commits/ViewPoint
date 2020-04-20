SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRLoadProc]
	/******************************************************
	* CREATED BY:	mh 6/13/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates HR Company set up.  Returns default country
	*			from HQCO
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	@hrco bCompany, @defaultcountry char(2) = null output, @msg varchar(100) output
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	 
	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if not exists(select top 1 1 from HRCO (nolock) where HRCo = @hrco)
	begin
		select @msg = 'Company ' + convert(varchar(4), @hrco) + ' not set up in HR Company.', @rcode = 1
		goto vspexit
	end
		
	select @defaultcountry = DefaultCountry from HQCO (nolock) where HQCo = @hrco

	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRLoadProc] TO [public]
GO
