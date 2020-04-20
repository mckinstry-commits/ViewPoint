SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPRGetStateLocalDflts]
/****************************************************************
* CREATED: TJL 03/01/10 - Issue #135490, Add Office TaxState & Office LocalCode to PR Employee Master
* MODIFIED:	 TJL 08/05/10 - Issue #140781, States do not default when Job is SPACE in text file.
*	
*
* USAGE:
*	Called from "bspPRAutoEarnInit", "bspPRTSSend", & "vspPRMyTimesheetSend" for the purpose of setting
*	a common set of defaults for TaxState, Unemployment State, Insurance State, & LocalCode.
*
* INPUT:
*	@prco
*	@employee
*	@jcco
*	@job
*	
* OUTPUT:
*	@taxstate		Tax State from Job, PR Company Office, or Employee
*	@localcode		LocalCode from Job, PR Company Office, or Employee
*	@unempstate		Unemployment State from Job or Employee
*	@insstate		Insurance State from Job or Employee
*   @errmsg		Error message
*
* RETURN:
*   0		Sucess
*   1		Failure
********************************************************/
(@prco bCompany = null, @employee bEmployee = null, @jcco bCompany = null, @job bJob = null, @localcode bLocalCode = null output, 
	@taxstate varchar(4) = null output, @unempstate varchar(4) = null output,  @insstate varchar(4) = null output, 
	@errmsg varchar(200) output)
	
as
set nocount on

declare @rcode int, @prtaxstateopt bYN, @prunempstateopt bYN, @prinsstateopt bYN, @prlocalopt bYN,
	@profficestate varchar(4), @profficelocal bLocalCode, @jobstate varchar(4), @joblocal bLocalCode,
	@emptaxstate varchar(4), @empunempstate varchar(4), @empinsstate varchar(4), 
	@emplocalcode bLocalCode, @useempstateopt bYN, @useempunempstateopt bYN,
	@useempinsstateopt bYN, @useemplocalopt bYN

select @rcode = 0, @localcode = null, @taxstate = null, @unempstate = null, @insstate = null 

if @prco is null				
	begin
	select @errmsg = 'Missing PR Company.', @rcode = 1
	goto vspexit
	end
if isnull(@employee, '') = ''		--An empty string past in for Employee would be 0 but evaluates this correctly
	begin
	select @errmsg = 'Missing PR Employee.', @rcode = 1
	goto vspexit
	end
if @job = ''
	begin
	--Issue #140781
	--An empty string past in for Job is bad data coming from the text file.  It happens.
	--It is easier to reset the value to NULL now rather than adjust each occurrance of 
	--@job later and have to retest each condition.
	set @job = null
	end
	
/* Get PR Company information */
select @prtaxstateopt=TaxStateOpt, @prunempstateopt=UnempStateOpt, @prinsstateopt=InsStateOpt, @prlocalopt=LocalOpt, 
	@profficestate=OfficeState, @profficelocal=OfficeLocal
from dbo.bPRCO with (nolock) where PRCo=@prco
if @@rowcount = 0
	begin
	select @errmsg = 'Missing PR Company Info.  Cannot determine State/Local defaults.', @rcode = 1
	goto vspexit
	end
	
/* Get Job information */
if isnull(@jcco, '') <> '' and @job is not null
	begin
	select @jobstate=PRStateCode, @joblocal=PRLocalCode
	from dbo.bJCJM with (nolock) where JCCo=@jcco and Job=@job
	if @@rowcount = 0
		begin
		select @errmsg = 'Missing Job Info.  Cannot determine State/Local defaults.', @rcode = 1
		goto vspexit
		end
	end
	
/* Get Employee information */
select @emptaxstate=isnull(WOTaxState,TaxState), @empunempstate=UnempState, @empinsstate=InsState,
	@emplocalcode=isnull(WOLocalCode,LocalCode), @useempstateopt=UseState, @useempunempstateopt=UseUnempState,
	@useempinsstateopt=UseInsState, @useemplocalopt=UseLocal
from dbo.bPREH with (nolock) where PRCo=@prco and Employee=@employee
if @@rowcount = 0
	begin
	select @errmsg = 'Missing PR Employee Info.  Cannot determine State/Local defaults.', @rcode = 1
	goto vspexit
	end
	
/*Determine States and LocalCode default values */
-- Tax State
if @prtaxstateopt = 'Y'
	begin
	if @job is not null select @taxstate = @jobstate		-- use Job State
	if @job is null select @taxstate = @profficestate		-- use Company Office State when there is no Job

	if @taxstate is not null and @emptaxstate is not null
		begin
		if @taxstate <> @emptaxstate
			begin
			/* Reciprocal check */
			if exists(select top 1 1 from dbo.HQRS where JobState=@taxstate and ResidentState=@emptaxstate)
				begin
				select @taxstate=@emptaxstate
				end
			end
		end
	end
if @taxstate is null or @useempstateopt = 'Y' select @taxstate = @emptaxstate  -- use Employee Tax State

-- Local Code - #132752 revised code to default null local if job posted but no job local specified
if @prlocalopt = 'Y' 
	begin
	if @job is not null select @localcode = @joblocal		-- use Job LocalCode
	if @job is null select @localcode = @profficelocal		-- use Company Office LocalCode when there is no Job
	end
if (@prlocalopt = 'N' and @localcode is null) or (@prlocalopt = 'Y' and @job is null and @localcode is null) or @useemplocalopt = 'Y' 
	select @localcode = @emplocalcode  -- use Employee LocalCode
	
-- Unemployment State
if @prunempstateopt = 'Y' select @unempstate = @jobstate	-- use Job State
if @unempstate is null or @useempunempstateopt = 'Y' select @unempstate = @empunempstate  -- use Employee Unempl State

-- Insurance State and Code
if @prinsstateopt = 'Y' select @insstate = @jobstate		-- use Job State
if @insstate is null or @useempinsstateopt = 'Y' select @insstate = @empinsstate -- use Employee Insur State
                     	
vspexit:

if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPRGetStateLocalDflts] TO [public]
GO
