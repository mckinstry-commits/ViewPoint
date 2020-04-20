SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMUsePostingRevCodeVal  Script Date: ******/
CREATE proc [dbo].[vspEMUsePostingRevCodeVal]
/***********************************************************
* CREATED BY:	TJL 12/07/06 - Issue #27979, 6x Recode EMUsePosting
* MODIFIED By: 
*
*
* USAGE:
*	Validates RevCode
*	Calls vspEMUsePostingFlagsGet for other values
*	Calls vspEMUsePostingRevRateUMDflt for other values
*
*
* INPUT PARAMETERS
*
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany, @emgroup bGroup, 
	@equip bEquip = null, @category bCat = null, @revcode bRevCode = null, @jcco bCompany = null,
    @job bJob = null, @postworkunits bYN = null output, @allowrateoride bYN = null output,
    @revbasis char(1) = null output, @hrfactor bHrs = null output, @updatehrs bYN = null output,
	@rate bDollar = null output, @timeum bUM = null output, @workum bUM = null output,
	@msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
if @emgroup is null
	begin
	select @msg = 'Missing EM Group.', @rcode = 1
	goto vspexit
	end
if @equip is null
	begin
	select @msg = 'Missing Equipment.', @rcode = 1
	goto vspexit
	end
if @revcode is null
	begin
	select @msg = 'Missing Revenue Code.', @rcode = 1
	goto vspexit
	end

/* Validate RevCode */
select @msg = Description
from EMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode
if @@rowcount = 0
	begin
	select @msg = 'Revenue Code is invalid.', @rcode = 1
	goto vspexit
	end

/* Retrieve EM usage flags. */
exec @rcode = vspEMUsePostingFlagsGet @emco, @emgroup, @equip, @category, @revcode, @jcco, @job, 
	@postworkunits output, @allowrateoride output, @revbasis output, @hrfactor output, 
    @updatehrs output, @msg output
if @rcode <> 0 goto vspexit

/* Retrieve Rate and UM values. */
exec @rcode = vspEMUsePostingRevRateUMDflt @emco, @emgroup, @equip, @category, @revcode, @jcco, @job, 
	@rate output, @timeum output, @workum output,
    @msg output
if @rcode <> 0 goto vspexit
   
vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingRevCodeVal] TO [public]
GO
