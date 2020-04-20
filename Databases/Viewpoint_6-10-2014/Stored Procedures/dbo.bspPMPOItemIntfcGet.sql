SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE  proc [dbo].[bspPMPOItemIntfcGet]
   /***********************************************************
   * Created By:	GF 03/03/2005
   * Modified By:	TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *
   *
   * USAGE:
   * Called from PMPOItems interfaced grid to return PMPO information
   * to display in the PM PO Items form.
   *
   *
   * INPUT PARAMETERS
   * POCo, PO, POItem
   *
   * OUTPUT PARAMETERS
   * PhaseDesc, CostTypeDesc
   * msg     error message
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   (@poco bCompany = 0, @po varchar(30) = null, @poitem bItem = null,
    @phasedesc bItemDesc output, @ctdesc bItemDesc output,
    @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @phase bPhase, @pmco bCompany, @project bJob, @phasegroup bGroup, @costtype bJCCType
   
   select @rcode = 0
   
   -- -- -- get POIT information
   select @phasegroup=PhaseGroup, @phase=Phase, @pmco=PostToCo, @project=Job, @costtype=JCCType
   from bPOIT with (nolock)
   where POCo=@poco and PO=@po and POItem=@poitem
   
   -- -- -- get phase description
   select @phasedesc = Description
   from bJCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
   if @@rowcount = 0
   	begin
   	select @phasedesc = Description
   	from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
   	end
   
   -- -- -- get cost type description
   select @ctdesc = Description
   from bJCCT where PhaseGroup=@phasegroup and CostType=@costtype
   
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPOItemIntfcGet] TO [public]
GO
