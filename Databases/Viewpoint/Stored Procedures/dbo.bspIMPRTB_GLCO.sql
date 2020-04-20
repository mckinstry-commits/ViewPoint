SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMPRTB_GLCO    Script Date: 8/28/99 9:34:28 AM ******/
CREATE proc [dbo].[bspIMPRTB_GLCO]
/********************************************************
* CREATED BY: 	DANF 05/31/00
* MODIFIED BY: GG 03/08/02 - #16459 - removed PRUseJCDept from bJCCO
*		TJL 03/15/10 - Issue #138549, GLCo not defaulting from EMCo on Mechanic TimeCard
*
* USAGE:
* 	Retrieves PR GLCo
*
* INPUT PARAMETERS:
*	PR Company
*	Employee
*   JC Company
*	Job
*   Phase
*	EM Company
*	Type
*
* OUTPUT PARAMETERS:
*	GL Company
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
   
(@prco bCompany = null, @employee bEmployee, @jcco bCompany, @job bJob, @phase bPhase, @emco bCompany, @type char(1), 
	@glco bCompany output, @msg varchar(60) output) as

set nocount on

declare @rcode int, @prglco bCompany, @prehglco bCompany
select @rcode = 0, @glco = null

if @prco is null
   	begin
   	select @msg = 'Missing PR Company#.  Cannot retrieve GLCo default.', @rcode = 1
   	goto bspexit
   	end
   
/* Job - GLCo is required in JCCO */
if @jcco is not null and @job is not null
	begin
	select @glco = GLCo from dbo.bJCCO with (nolock) where JCCo = @jcco
	end

/* Mechanic - GLCo is required in EMCO */
if @type = 'M' and @emco is not null
	begin
	select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
	end

/* If still null at this point. - GLCo is required in PR Company */	
if @glco is null
	begin
	select @prehglco = e.GLCo, @prglco = p.GLCo 
	from bPREH e with (nolock) 
	join bPRCO p with (nolock) on p.PRCo = e.PRCo
	where e.PRCo = @prco and e.Employee = @employee
		
	select @glco = isnull(@prehglco, @prglco)
	end

/* If still null then PR Company has not even been setup. */	
if @glco is null
	begin
	select @msg = 'Payroll company missing.   Cannot retrieve GLCo default.', @rcode=1
	end
   
bspexit:
if @rcode <> 0 select @msg = isnull(@msg, 'GL Company')
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_GLCO] TO [public]
GO
