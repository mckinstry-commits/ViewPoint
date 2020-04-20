SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspPRCAEmployerItemsVal
	/******************************************************
	* CREATED BY:	markh 08/26/09 
	* MODIFIED By: 
	*
	* Usage:  
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
   
   	(@prco bCompany, @taxyear char(4), @t4boxnumber smallint, @msg varchar(255) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if @taxyear is null
	begin
		select @msg = 'Missing Tax Year.', @rcode = 1
		goto vspexit
	end

	if @t4boxnumber is null
	begin
		select @msg = 'Missing T4 Box Number.', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from PRCAItems (nolock) where  
		PRCo = @prco and TaxYear = @taxyear and T4BoxNumber = @t4boxnumber)
	begin
		select @msg = T4BoxDescription from PRCAItems (nolock) 
		where PRCo = @prco and TaxYear = @taxyear and T4BoxNumber = @t4boxnumber
	end
	else
	begin
		select @msg = 'T4 Box Number has not been set up in PR Canada T4 Items.', @rcode = 1
		goto vspexit
	end

	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCAEmployerItemsVal] TO [public]
GO
