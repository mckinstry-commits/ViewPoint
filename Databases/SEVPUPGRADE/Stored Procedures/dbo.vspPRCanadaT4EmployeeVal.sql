SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspPRCanadaT4EmployeeVal]
	/******************************************************
	* CREATED BY:  Mark H 
	* MODIFIED By: 
	*
	* Usage:  Validates Employee and checks for existance in
	*		  PRCAEmployees
	*	
	*
	* Input params:
	*
	*	@prco - Payroll Company
	*	@taxyear - Tax Year
	*	@employee - Employee (Number or Sort Name)
	*
	* Output params:
	*	@employeeout - Employee Output 
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @taxyear char(4), @employee varchar(15), @employeeout bEmployee output, @msg varchar(80) output
   	   	
	as 
	set nocount on
	declare @rcode int
   	
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
	--PRCAEmployees they must exist in PREH first.
	 exec @rcode = bspPREmplVal @prco, @employee, 'X', @employeeout output, null, null, null, null, null, null, null, null, null, @msg output

	if @rcode = 0
	begin
		if not exists(select 1 from PRCAEmployees where PRCo = @prco and TaxYear = @taxyear and Employee = @employeeout)
		begin
			select @msg = 'Employee does not exist in PR Canada T4 Employees.', @rcode = 1
			goto vspexit
		end
	end
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4EmployeeVal] TO [public]
GO
