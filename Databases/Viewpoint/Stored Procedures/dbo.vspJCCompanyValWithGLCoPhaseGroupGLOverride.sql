SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJCCompanyValWithGLCoPhaseGroupGLOverride]
   /*************************************
   * CREATED: Danf 03/27/2006
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
   	(@jcco bCompany = 0, @glco bCompany output, @phasegroup bGroup = null output, @gloverride bYN = null output, @msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @jcco = 0
   	begin
   	select @msg = 'Missing JC Company#', @rcode = 1
   	goto bspexit
   	end
   
   exec @rcode = bspJCCompanyVal @jcco, @msg output
   if @rcode <> 0 goto bspexit
   
   select @glco = GLCo, @gloverride = GLCostOveride from bJCCO with (nolock) where JCCo = @jcco
   select @phasegroup = PhaseGroup from bHQCO with (nolock) where HQCo=@jcco
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCompanyValWithGLCoPhaseGroupGLOverride] TO [public]
GO
