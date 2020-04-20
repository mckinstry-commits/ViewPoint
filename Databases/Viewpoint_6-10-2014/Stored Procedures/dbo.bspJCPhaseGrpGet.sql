SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPhaseGrpGet    Script Date: 8/28/99 9:35:05 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCPhaseGrpGet    Script Date: 2/12/97 3:25:07 PM ******/
   CREATE    proc [dbo].[bspJCPhaseGrpGet]
   /********************************************************
   * CREATED BY: 	LM 9/27/96
   * MODIFIED BY: TV - 23061 added isnulls
   *
   * USAGE:
   * 	Retrieves the JC Phase Group from bHQCO
   *
   * INPUT PARAMETERS:
   *	JC Company number
   *
   * OUTPUT PARAMETERS:
   *	Phase Group from bHQCO
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@hqco bCompany, @phasegroup bGroup output, @msg varchar(60) output)
   as
   set nocount on 
   	declare @rcode int
   	select @rcode = 0
   	
   
   select @phasegroup = PhaseGroup from bHQCO with (nolock) where HQCo = @hqco
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg = 'HQ company does not exist.', @rcode=1, @phasegroup=0
   
   if @phasegroup is Null 
      select @msg = 'Phase group not setup for company ' + isnull(convert(varchar(3),@hqco),'') , @rcode=1, @phasegroup=0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPhaseGrpGet] TO [public]
GO
