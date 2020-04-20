SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRW2LoadProc]
	/******************************************************
	* CREATED BY:	mh 9/8/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates company and returns info for form load
	*	
	*
	* Input params:
	*	
	*	@co - Company
	*
	* Output params:
	*
	*	@country - Default Country from HQST
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@co bCompany, @defaultcountry char(2) output, @msg varchar(100) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	exec @rcode = vspCompanyVal @co, 'PR', @msg output

	if @rcode = 1 
	begin
		goto vspexit
	end

	select @defaultcountry = DefaultCountry from HQCO where HQCo = @co
 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRW2LoadProc] TO [public]
GO
