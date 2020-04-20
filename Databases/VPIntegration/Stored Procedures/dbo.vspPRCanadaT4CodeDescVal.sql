SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspPRCanadaT4CodeDescVal
	/******************************************************
	* CREATED BY:  MarkH 
	* MODIFIED By: 
	*
	* Usage:	Returns T4 Code Description
	*	
	*
	* Input params:
	*	
	*	@prco - PR Company
	*	@taxyear - Tax Year
	*	@t4codenumber - T4 Box Number  	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @t4codenumber smallint , @msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int
   	
	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	if @taxyear is null
	begin
		select @msg = 'Missing Tax Year!', @rcode = 1
		goto vspexit
	end

	if @t4codenumber is null
	begin
		select @msg = 'Missing T4 Box Number!', @rcode = 1
		goto vspexit
	end

	select @msg = T4CodeDescription from PRCACodes (nolock)
	where PRCo = @prco and TaxYear = @taxyear and T4CodeNumber = @t4codenumber
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4CodeDescVal] TO [public]
GO
