SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[bspPMOurFirmGet]
   /********************************************************
   * CREATED BY:   GF 07/23/2001
   * MODIFIED BY:  SP 01/07/2013   Add param for Project and check for OurFirm in JCJM first
   *
   * USAGE:
   * 	Retrieves the Our Firm from JCJM and, if not found, then bPMCO
   *
   * INPUT PARAMETERS:
   *	PM Company number
   *
   * OUTPUT PARAMETERS:
   *	OurFirm from bPMCO
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@pmco bCompany = null, @project bJob = null, @ourfirm bFirm output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   set @rcode = 0
   
   if @pmco is null
       begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end
   
	select @ourfirm=OurFirm from dbo.JCJMPM where JCCo = @pmco and Job = @project
   	
   -- if missing project our firm - get from PMCO
   if isnull(@ourfirm,0) = 0
   	begin
   	select @ourfirm = OurFirm from dbo.PMCO where PMCo=@pmco
   	end
      
   if isnull(@ourfirm,0) = 0
       begin
       select @msg = 'Our Firm not setup for Company ' + convert(varchar(3), isnull(@pmco,'')) + ' in PM!', @rcode=1
       goto bspexit
       end
      
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMOurFirmGet] TO [public]
GO
