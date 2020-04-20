SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRW2EmployeeVal]
	/******************************************************
	* CREATED BY:	MarkH 11/26/2007 
	* MODIFIED By: 
	*
	* Usage:
	*	
	*	Validte PR Employee against PRWE.  Used by PRW2Print
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
   
   	@prco bCompany, @employee varchar(15), @employeeout bEmployee output, @taxyear char(4), @msg varchar(80) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	if @employee is null
	begin
		select @msg = 'Missing Employee!', @rcode = 1
		goto vspexit
	end

	--Validate against PREH.  This will resolve sort name.  In order for an Employee to exist in 
	--PRWE they must exist in PREH first.
	 exec @rcode = bspPREmplVal @prco, @employee, 'X', @employeeout output, null, null, null, null, null, null, null, null, null, @msg output

	if @rcode = 0
	begin
		if not exists(select 1 from PRWE where PRCo = @prco and Employee = @employeeout and TaxYear = @taxyear)
		begin
			select @msg = 'Employee does not exist in PR W2 Employees.', @rcode = 1
			goto vspexit
		end
	end
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRW2EmployeeVal] TO [public]
GO
