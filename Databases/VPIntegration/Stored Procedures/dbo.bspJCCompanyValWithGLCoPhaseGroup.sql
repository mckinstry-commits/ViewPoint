SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJCCompanyValWithGLCoPhaseGroup]
/*************************************
* CREATED: Danf 05/21/02
*		TV - 23061 added isnulls
*		TJL 12/06/06 - Issue #27979, 6x Recode EMUsePosting (Made vDDFI entries to all 6x forms, NA elsewhere).
*						Added outputs for GLCostOveride and GLRevOverides and PostClosedJobs
*		GF 12/12/2007 - issue #25669 separate post closed job flags in JCCO enhancement
*
*			
* validates JC Company number and returns Description and information from JCCo from HQCo
*			
* Pass:
*	JC Company number
*
* Success returns:
*	0, Company description, GLCo  from bJCCO
*
* Error returns:
*	1 and error message
**************************************/
(@jcco bCompany = 0, @jccoglco bCompany output, @phasegroup bGroup = null output, @glcostoveride bYN output,
 @glrevoveride bYN output, @postclosedjobs bYN output, @postsoftclosedjobs bYN output,
 @msg varchar(60) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company#.', @rcode = 1
	goto bspexit
	end

select @jccoglco = j.GLCo, @phasegroup = h.PhaseGroup, @postclosedjobs = j.PostClosedJobs,
	@glrevoveride = j.GLRevOveride,  @glcostoveride = j.GLCostOveride, @msg = h.Name,
	@postsoftclosedjobs=PostSoftClosedJobs
from bJCCO j
join bHQCO h with (nolock) on h.HQCo = j.JCCo
where j.JCCo = @jcco and h.HQCo = @jcco
if @@rowcount = 0
	begin
	select @msg = 'JC Company invalid.', @rcode = 1
	goto bspexit
	end



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCompanyValWithGLCoPhaseGroup] TO [public]
GO
