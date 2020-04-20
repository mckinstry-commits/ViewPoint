SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspPRMyTimesheetJobVal]
	/******************************************************
	* CREATED BY: 
	* MODIFIED By:	MarkH 02/05/10 - 137537.  Use PREHFullName to get Employee Craft.
	*					Otherwise reciprocal craft check will fail if bEmployee
	*					security is on PREH.
	*
	* Usage:	Validates Job and returns recip Craft and Locked Phases flag.
	*	
	*
	* Input params:
	*	
	*	@prco - Payroll Company
	*	@employee - Employee
	*	@jcco - Job Company
	*	@job - Job
	*	
	*
	* Output params:
	*
	*	@craft - Craft or reciprocal Craft
	*	@lockphases - Locked Phases flag
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @employee bEmployee, @jcco bCompany, @job bJob, @craft bCraft output, 
   	@lockphases bYN output, @msg varchar(100) output)
	as 
	set nocount on

	declare @rcode int, @status tinyint, /*@lockphases bYN,*/ @taxcode bTaxCode, @contract bContract,
   	@address varchar(60), @city varchar(30), @state varchar(4), @zip bZip, 
	@pocompgroup varchar(10), @slcompgroup varchar(10), @address2 varchar(60), @country char(2),
	@jobcraft bCraft, @template smallint

	select @rcode = 0

	exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
	@taxcode output, @address output, @city output, @state output, @zip output,
	@pocompgroup output, @slcompgroup output, @address2 output, @country output, null, 
	@msg output

	if @rcode = 1
	begin
		goto vspexit
	end

	if @status = 0
	begin
		select @msg = 'Job status cannot be pending', @rcode = 1
		goto vspexit
	end

	select @msg=[Description], @template = CraftTemplate
	from JCJM with (nolock) 
	where JCCo=@jcco and Job=@job

	--Issue 137537 Use unsecured view.  
	--select @craft = Craft 
	--from PREH (nolock) 
	--where PRCo = @prco and Employee = @employee
	
	select @craft = Craft 
	from PREHFullName with (nolock)
	where PRCo = @prco and Employee = @employee
	--end Issue 137537
	
	select @jobcraft=JobCraft from PRCT where PRCo = @prco and 
	Craft = @craft and Template = @template and RecipOpt='O'

	if @jobcraft is not null
	begin
		select @craft = @jobcraft
	end

	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetJobVal] TO [public]
GO
