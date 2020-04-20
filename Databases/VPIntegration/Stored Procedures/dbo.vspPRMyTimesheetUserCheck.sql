SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRMyTimesheetUserCheck]
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By: 
	*
	* Usage:	Check the vpuser id and determine if user is foreman or 
	*			regular employee
	*	
	*
	* Input params:
	*
	*	@userid - VP UserId	
	*	
	*
	* Output params:
	*
	*	@prco - Payroll Company
	*	@employee - PR Employee 
	*	@isforeman - Foreman flag
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@userid bVPUserName, @prco bCompany output, @entryemployee bEmployee output, 
	@myTimesheetRole tinyint output, @employeename VARCHAR(83) output,
	@prgroup bGroup output, @allownophase bYN output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @userid is null
	begin
		select @msg = 'Missing VP User ID!', @rcode = 1
		goto vspexit
	end

	select @prco = PRCo, @entryemployee = Employee, @myTimesheetRole = MyTimesheetRole
	from dbo.DDUP (nolock) where VPUserName = @userid 

	if @prco is not null and @entryemployee is not null
	begin
		select @employeename = FullName, @prgroup = PRGroup
		from dbo.PREHFullName with (nolock) where PRCo = @prco and Employee = @entryemployee
	end
	 
	select @allownophase = AllowNoPhase from PRCO nolock where PRCo = @prco 

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetUserCheck] TO [public]
GO
