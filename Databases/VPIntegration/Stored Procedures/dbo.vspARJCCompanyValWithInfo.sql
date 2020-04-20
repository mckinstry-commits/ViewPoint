SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARJCCompanyValWithInfo  ******/
CREATE  proc [dbo].[vspARJCCompanyValWithInfo]
/*************************************
* CREATED:	TJL 10/24/05 - Issue #27709, 6x rewrite
* Modified By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
* 
*
* Pass:
*	JC Company number
*
* Success returns:
*	0 and other info
*
* Error returns:
*	1 and error message
**************************************/
(@jcco bCompany = null, @glco bCompany output,  @glrevoveride bYN output, @glcostoveride bYN output, 
 @postclosedjobs bYN output, @phasegroup bGroup output, @taxgroup bGroup output,
 @postsoftclosedjobs bYN output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company#', @rcode = 1
	goto vspexit
	end

exec @rcode = bspJCCompanyVal @jcco, @msg output
if @rcode <> 0 goto vspexit

select @glco = j.GLCo, @glrevoveride = j.GLRevOveride, @glcostoveride = j.GLCostOveride, 
	@postclosedjobs = j.PostClosedJobs, @phasegroup = h.PhaseGroup, @taxgroup = h.TaxGroup,
	@postsoftclosedjobs = j.PostSoftClosedJobs
from bJCCO j with (nolock)
join bHQCO h with (nolock) on h.HQCo = j.JCCo
where j.JCCo = @jcco

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARJCCompanyValWithInfo] TO [public]
GO
