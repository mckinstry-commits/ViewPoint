SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSJCCompanyVal]
   /************************************************
   * Created By:  GF 06/01/2000
   * Modified By: GF 09/09/2002 - #18343 - added Tax Group to output params
   *
   * validates JC Company number, Used in MSQuote, MSTicEntry
   *
   * Pass:
   *	JC Company number
   *
   * Success returns:
   *   PhaseGroup  PhaseGroup from bHQCO
   *	0 and Company name from bHQCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@jcco bCompany = null, @phasegroup bGroup = null output, @taxgroup bGroup = null output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company#', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bJCCO where JCCo=@jcco)
   	begin
   	select @msg = 'Not a valid JC Company', @rcode = 1
   	goto bspexit
   	end
   
   -- get phase group
   select @msg=Name, @phasegroup=PhaseGroup, @taxgroup=TaxGroup
   from bHQCO where HQCo=@jcco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid JC Company!', @rcode = 1
   	goto bspexit
   	end



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSJCCompanyVal] TO [public]
GO
