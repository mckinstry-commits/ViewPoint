SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPREmplPayStubVal]
	/******************************************************
	* CREATED BY:	markh 2/18/2009 
	* MODIFIED By: 
	*
	* Usage:	Validate Employee and restrict input to Employees
	*			with PayMethodDelivery value <> 'N'
	*	
	*
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *
    * Output params:
    *	@emplout	Employee number
    *	@msg		Employee Name or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq int, @empl varchar(15), 
	@emplout bEmployee output, @msg varchar(80) output)
	
	as 
	set nocount on
	
	declare @rcode int
   	
	select @rcode = 0

	if @empl is null
   	begin
   		select @msg = 'Missing Employee.', @rcode = 1
   		goto vspexit
   	end

	declare @sortname bSortName, @lastname varchar(30),
	@firstname varchar(30), @inscode bInsCode, @dept bDept, @craft bCraft,
	@class bClass, @jcco bCompany, @job bJob

	exec @rcode = bspPREmplVal @prco, @empl, 'X', @emplout output, @sortname output, 
	@lastname output, @firstname output, @inscode output, @dept output, @craft output, @class output, 
	@jcco output, @job output, @msg output

	if @rcode = 0
	begin
		if not exists(select 1 from dbo.PRSQ (nolock) 
			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and
			Employee = @emplout and PaySeq = @payseq)
		begin
			select @msg = 'Pay Seq Control record does not exist for this Employee.'
			select @rcode = 1
		end
		else
		begin
			if exists(select 1 from dbo.PREH (nolock) 
			where PRCo = @prco and Employee = @emplout and Email is null)
			begin
				select @msg = 'Employee does not have an email address in PR Employees'
				select @rcode = 1
			end
		end
	end


	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREmplPayStubVal] TO [public]
GO
