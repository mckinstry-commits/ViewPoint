SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4ItemDescVal]
	/******************************************************
	* CREATED BY: mh 06/29/2009 
	* MODIFIED By: 
	*
	* Usage:	Returns T4 Item Description
	*	
	*
	* Input params:
	*	
	*	@prco - PR Company
	*	@taxyear - Tax Year
	*	@t4boxnumber - T4 Box Number  	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/

   	(@prco bCompany, @taxyear char(4), @t4boxnumber smallint , @msg varchar(255) output)
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

	if @t4boxnumber is null
	begin
		select @msg = 'Missing T4 Box Number!', @rcode = 1
		goto vspexit
	end

	select @msg = T4BoxDescription from PRCAItems (nolock)
	where PRCo = @prco and TaxYear = @taxyear and T4BoxNumber = @t4boxnumber
	 
	vspexit:

	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4ItemDescVal] TO [public]
GO
