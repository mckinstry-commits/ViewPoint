SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4EDLCodeVal]
	/******************************************************
	* CREATED BY:	markh 09/03/09
	* MODIFIED By: 
	*
	* Usage:	Validates EDL Code
	*	
	*
	* Input params:
	*
	*	@prco - PR Company
	*	@taxyear - Tax Year
	*	@type - EDL Type
	*	@code - EDL Code	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @type char(1),  @code bEDLCode, @msg varchar(100) output)
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

	if @type is null
	begin	
		select @msg = 'Missing EDL Type.', @rcode = 1
		goto vspexit
	end

	if @code is null
	begin
		select @msg = 'Missing EDL Code.', @rcode = 1
		goto vspexit
	end

	if @type = 'E'
	begin
		if exists(select 1 from PREC where PRCo = @prco and EarnCode = @code)
		begin
			select @msg = [Description] from PREC where PRCo = @prco and EarnCode = @code
		end
		else
		begin
			select @msg = 'Invalid Earnings code.', @rcode = 1
		end
	end
	else
	begin
		if exists(select 1 from PRDL where PRCo = @prco and DLCode = @code and DLType = @type)
		begin
			select @msg = [Description] from PRDL where PRCo = @prco and DLCode = @code and DLType = @type
		end
		else
		begin
			select @msg = 'Invalid Deduction/Liability code.',@rcode = 1
		end
	end
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4EDLCodeVal] TO [public]
GO
