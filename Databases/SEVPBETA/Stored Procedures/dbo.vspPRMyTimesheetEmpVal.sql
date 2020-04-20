SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPRMyTimesheetEmpVal]
	/******************************************************
	* CREATED BY:	markh 
	* MODIFIED By:  markh -Issue 137537  Switch employee validation to 
	*					bspPREmplValName to bypass security.  
	*               ericv - TK-04202 Add null default values to some output parameters.
	*				DAN SO - 01/10/2013 - D-06473/137931 - do not allow inactive employees
	*
	* Usage:	Employee validation routine for MyTimesheetEntry
	*	
	*
	* Input params:
	*	
	*	@prco - Payroll Company
	*	@empl - Employee input.  Could be numeric or sort
	*	@entryemplprgroup - PR Group for entry employee
	*	
	* Output params:
	*
	*	@emplout - Employee number
	*	@craft - Craft
	*	@class - Class
	*	@jcco - JC Company
	*	@job - Job
	*	@shift - Shift
	*	@earncode - Earn Code
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @empl varchar(15), @entryemplprgroup bGroup, @emplout bEmployee=null output, 
	@craft bCraft=null output, @class bClass=null output, @jcco bCompany=null output, 
	@job bJob=null output, @shift tinyint=null output, @earncode bEDLCode=null output, @msg varchar(100) output)

	as 
	set nocount on

	declare @rcode int, @sortname bSortName, @lastname varchar(30), @firstname varchar(30),
	@inscode bInsCode, @dept bDept, @crafttemplate smallint, @jobcraft bCraft, @emplprgroup bGroup,
	@EmployeeActiveYN bYN

	select @rcode = 0

	--Issue 137537 Use bspPREmplValName.  This procedure uses view non securable view PREHFullName.
	
	--exec @rcode = bspPREmplVal @prco, @empl, 'X', @emplout output, @sortname output, @lastname output,
	--@firstname output, @inscode output, @dept output, @craft output, @class output, @jcco output,
	--@job output, @msg output
   
	exec @rcode = bspPREmplValName @prco, @empl, 'X', @emplout output, @sortname output, @lastname output,
	@firstname output, @inscode output, @dept output, @craft output, @class output, @jcco output,
	@job output, @msg output
	--end 137537
	
	if @rcode = 0 
	begin
	
		--Issue 137537 query the table directly for Shift/EarnCode/Group.  
		--select @shift = Shift, @earncode = EarnCode, @emplprgroup = PRGroup 
		--from PREH (nolock) 
		--where PRCo = @prco and Employee = @emplout
		
		select @shift = Shift, @earncode = EarnCode, @emplprgroup = PRGroup, @EmployeeActiveYN = ActiveYN
		from bPREH  with (nolock) 
		where PRCo = @prco and Employee = @emplout
		--end 137537
		
		
		IF @EmployeeActiveYN = 'N' -- D-06473 --
			BEGIN
				SET @msg = 'Employee is NOT an active PR Employee!'
				SET @rcode = 1
				GOTO vspexit
			END
		ELSE
			BEGIN
				if @emplprgroup <> @entryemplprgroup
				begin
					select @msg = 'Employee must be a member of Entry Employee''s Payroll Group.', @rcode = 1
					goto vspexit
				end
			END

		if @jcco is not null and @job is not null
		begin
			select @crafttemplate = CraftTemplate from JCJM (nolock) where JCCo = @jcco and Job = @job
	
			if @crafttemplate is not null
			begin
				--This uses the craft returned from PREH and the Template returned from JCJM.
				select @jobcraft=JobCraft from PRCT (nolock) where PRCo = @prco and 
				Craft = @craft and Template = @crafttemplate and RecipOpt='O'

				if @jobcraft is not null
				begin
					select @craft = @jobcraft
				end
			end
		end
	end
    	
	select @rcode = 0
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetEmpVal] TO [public]
GO
