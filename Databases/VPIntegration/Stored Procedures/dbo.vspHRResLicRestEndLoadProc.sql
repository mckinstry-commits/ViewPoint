SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure dbo.vspHRResLicRestEndLoadProc
	/******************************************************
	* CREATED BY:	MH 6/12/2008 
	* MODIFIED By: 
	*
	* Usage:
	*	
	*
	* Input params:
	*	
	*	@hrco bCompany
	*	
	*
	* Output params:
	*
	*	@hqCountry - DefaultCountry
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @hqCountry varchar(4) output, @msg varchar(80) = '' output)

	as 
	set nocount on
	declare @rcode int

	select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto vspexit
	end

	if not exists(select 1 from HRCO where HRCo = @hrco) 
	begin
		select @msg = 'Company# ' + convert(varchar(4), @hrco) + ' not setup in HR', @rcode = 1
		goto vspexit
	end

	select @hqCountry = DefaultCountry from HQCO (nolock) where HQCo = @hrco
 
	vspexit:

	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHRResLicRestEndLoadProc] TO [public]
GO
