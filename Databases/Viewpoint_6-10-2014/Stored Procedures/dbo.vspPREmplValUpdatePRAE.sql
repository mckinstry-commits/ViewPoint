SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspPREmplValUpdatePRAE]
	/******************************************************
	* CREATED BY:  Mark H 02/10/2010
	* MODIFIED By: 
	*
	* Usage:  If Update Auto Earnings flag in PR Employees 
	*			is "Y" then check PR Auto Earnings for Earnings
	*			code value in PR Employees.
	*	
	*
	* Input params:
	*
	*	@prco - Payroll Company
	*	@employee - Employee
	*	@updatePREA - Update Auto Earnings Flag
	*	@earncode - Earnings Code from PR Employees
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @employee bEmployee, @updatePREA bYN, @earncode bEDLCode, @msg varchar(100) output)
   	
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	
	if @prco is null
	begin
		select @msg = 'Missing Payroll Company!', @rcode = 1
		goto vspexit
	end
	
	if @employee is null
	begin
		select @msg = 'Missing Employee!', @rcode = 1
		goto vspexit
	end
	
	if @earncode is null
	begin
		select @msg = 'Missing Earnings Code!', @rcode = 1
		goto vspexit
	end
	
	if isnull(@updatePREA, 'N') = 'Y'
	begin
		if not exists(select 1 from PRAE with (nolock) where PRCo = @prco
		and Employee = @employee and EarnCode = @earncode)
		begin
			select @msg = 'Earnings code in PR Employee Master does not exist in PR Automatic Earnings.', @rcode = 1
			goto vspexit
		end
	
	end

	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPREmplValUpdatePRAE] TO [public]
GO
