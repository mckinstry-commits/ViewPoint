SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
   CREATE proc [dbo].[bspJCVCOSTTYPEForPE]
   /***********************************************************
   * Created By:  LM  04/23/97
   * Modified By:	GF 04/11/2001 - issue 12687 allow linked cost type no linked to cost type in bJCCH
   *				GF 07/28/2003 - issue #21932 - allow linked cost type.
   *				TV - 23061 added isnulls
   *				GF 09/07/2004 - issue #25436 - cost type must exist in bJCCH.
   *				DANF 08/25/2005 - Added Parent of Lined Cost Type for Progress Grid and form refresh.
*					GF 01/03/2008 - issue #122756 need to include UM check in where clause for estimate units.
*
   *
   *
   * USAGE:
   * validates JC Phase/CostType.  Check for valid phase/costtype according to
   * standard Job/Phase/CostType validation. Must exist in bJCCH for Job/Phase.
   * no job passed, no phase passed.
   *
   *
   * INPUT PARAMETERS
   *    co         Job Cost Company
   *    job        Valid job
   *    phase      valid phase
   *    costtype   cost type to validate
   *    PhaseGroup   valid phase group
   *
   * OUTPUT PARAMETERS
   *    phasedesc       Description of phase from JCJP
   *    ctdesc          five character abbreviation
   *    um              unit of measure from JCCH or JCPC.
   *    Curr Estimate   Total estimated units from bJCCD
   *    Curr Projected  Total projected units from JCCD
   *    Curr Completed  Total actual units from JCCD
   *    plugged	      Whether or not projected value is plugged
   *    msg             cost type abbreviation, or error message.
   *    It will validate by first checking in JCCT then JCCH
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   (@jcco bCompany = 0, @job bJob = null, @phase bPhase = null, @PhaseGroup tinyint=null,
    @costtype varchar(10) = null, @actualdate bDate=0, @phasedesc bDesc=null output,
    @ctdesc bDesc=null output, @um bUM=null output, @estimate bUnits=0 output, @projected bUnits=0 output,
    @actual bUnits=0 output, @plugged char(1)=null output, @parentlinkedct bYN = null output, 
	@costtypeout bJCCType = null output, @msg varchar(30)=null output)
   as
   set nocount on
     
   declare @rcode int, @linkprogress int, @active char(1)
     
   select @rcode = 0, @parentlinkedct = 'N'
     
   if @jcco is null
     	begin
     	select @msg = 'Missing JC Company!', @rcode = 1
     	goto bspexit
     	end
     
   if @job is null
     	begin
     	select @msg = 'Missing Job!', @rcode = 1
     	goto bspexit
     	end
     
   if @phase is null
     	begin
     	select @msg = 'Missing Phase!', @rcode = 1
     	goto bspexit
     	end
     
   if @costtype is null
     	begin
     	select @msg = 'Missing Cost Type!', @rcode = 1
     	goto bspexit
     	end
     
   -- -- -- Validate the Company
   if (select count(*) from bJCCO with (nolock) where JCCo=@jcco)<>1
     	begin
     	select @msg = 'Company not set up in JC Company!', @rcode = 1
     	goto bspexit
     	end
     
   -- -- -- Validate Job
   if (select count(*) from bJCJM with (nolock) where JCCo=@jcco and Job=@job)<>1
     	begin
     	select @msg = 'Job not in Job Master!', @rcode = 1
     	goto bspexit
     	end
     
   -- -- -- Validate Phase in Job Phases - must exists here to use in Progress Entry
   select @phasedesc=Description from bJCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@phase
   if @@rowcount = 0
         begin
         select @ctdesc = 'Phase not in Job Phases!', @rcode = 1
         goto bspexit
         end
     
   -- -- -- validate phase group from bHQGP
   if (select count(*) from bHQGP with (nolock) where Grp=@PhaseGroup)<>1
     	begin
     	select @msg = 'Phase Group not in HQGP!', @rcode = 1
     	goto bspexit
     	end
     
   exec @rcode =  dbo.bspJCVCOSTTYPE @jcco = @jcco, @job = @job, @PhaseGroup = @PhaseGroup, @phase = @phase, @costtype = @costtype, 
		@override = 'N', @desc = @ctdesc output, @um = @um output, @costtypeout = @costtypeout output, @msg = @msg output
   if @rcode <> 0
         begin
         select @ctdesc = @msg, @rcode=1
         goto bspexit
         end
    
   -- -- -- Check CostHeader
	select @plugged=Plugged
	from bJCCH with (nolock)
	where JCCo = @jcco and Job = @job and Phase = @phase and CostType=@costtypeout
	if @@rowcount = 0
	begin
	select @ctdesc = 'Cost Type not setup for phase in Job Phases!', @rcode = 1
	goto bspexit
	end

   select @parentlinkedct = isnull(dbo.vfJCParentOfLinkedCT(@PhaseGroup, @costtypeout),'N')

---- get estimate values from bJCCD for job-phase-cost type using actual date
select @estimate=isnull(sum(JCCD.EstUnits),0), @projected=isnull(sum(JCCD.ProjUnits),0), @actual=isnull(sum(JCCD.ActualUnits),0)
from bJCCD JCCD with (nolock)
join JCCH JCCH with (nolock) on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.PhaseGroup=JCCD.PhaseGroup
and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType
where JCCD.JCCo=@jcco and JCCD.Job=@job and JCCD.Phase=@phase 
and JCCD.CostType=@costtypeout and JCCD.ActualDate<=@actualdate and JCCH.UM=JCCD.UM
   
      
   
   bspexit:
   	select @msg = isnull(@ctdesc,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPEForPE] TO [public]
GO
