SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRJCCompanyVal   Script Date: 12/3/97 3:25:03 PM ******/
   CREATE  proc [dbo].[bspPRJCCompanyVal]
   /*************************************
   * CREATED: kb 1/17/98
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *
   * validates JC Company number and returns Description and information from JCCofrom HQCo
   *
   * Pass:
   *	JC Company number
   *
   * Success returns:
   *	0, Company name, Phase Group  from bJCCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@jcco bCompany = 0, @glco bCompany= null output, @phasegrp bGroup = null output, 
   		@msg varchar(60) output)
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
   if @rcode<>0 goto bspexit
   
   select @phasegrp=bHQCO.PhaseGroup, @glco = bJCCO.GLCo from bJCCO join bHQCO on bHQCO.HQCo=bJCCO.JCCo
   	 where bJCCO.JCCo = @jcco
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRJCCompanyVal] TO [public]
GO
