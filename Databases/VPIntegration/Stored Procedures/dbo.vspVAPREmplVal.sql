SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspVAPREmplVal]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:	Validates PR Employee 
	*	
	*
	* Input params:
	*	
	*		@co - Company	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@vpusername bVPUserName, @prco bCompany, @employee varchar(15), @empout int output, @msg varchar(75) output)

	as 
	set nocount on
  	
	declare @sortname bSortName, @lastname varchar(30), @firstname varchar(30),
	@inscode bInsCode, @dept bDept, @craft bCraft, @class bClass, @jcco bCompany,
	@job bJob, @rcode int

	select @rcode = 0
	
	exec @rcode = bspPREmplVal @prco, @employee, 'X', @empout output, @sortname output, @lastname output, 
	@firstname output, @inscode output, @dept output, @craft output, @class output, @jcco output, 
	@job output, @msg output
 
	if @rcode = 0
	begin
		--Check for previous usage in VA - DDUP
		if exists(select 1 from DDUP where PRCo = @prco and Employee = @empout and 
		VPUserName <> @vpusername)
		begin
			select @msg = 'Employee number currently assigned to another VA User.', @rcode = 1
		end
	end
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVAPREmplVal] TO [public]
GO
