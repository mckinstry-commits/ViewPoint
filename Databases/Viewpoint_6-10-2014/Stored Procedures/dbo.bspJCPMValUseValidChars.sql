SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspJCPMValUseValidChars]
   /***********************************************************
    * CREATED BY: SE   12/9/97
    * MODIFIED By : SE 12/9/97
    *             : DANF 03/16/00 Changed valid part of phase validation.
    *				TV - 23061 added isnulls
    * USAGE:
    * validates JC Phase from Phase Master.
    * First uses Whole phase, then valid part of phase
   
    * no phase passed, no phase found in JCPM.
    *
    *  If Job is passed then phase description will come from JCJP if available.
    *
    * INPUT PARAMETERS
    *   JCCo        JCCO to get ValidPhaseChars From
    *   PhaseGroup  JC Phase group for this company
    *   Phase       Phase to validate
    *
    * OUTPUT PARAMETERS
    *   @Desc     Description of phase
    *   @msg      error message if error occurs otherwise Description of Template description
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@jcco bCompany, 
   @PhaseGroup tinyint, 
   @phase bPhase = null, 
   @job bJob = null, 
   @msg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @validphasechars int, @inputmask varchar(30), @pphase bPhase
   
   select @rcode = 0, @msg='', @pphase = null
   
   if @phase is null
   	begin
   	select @msg = 'Missing Phase', @rcode = 1
   	goto bspexit
   	end
   
   -- validate phase
   select @msg = Description
   from JCPM with (nolock) where PhaseGroup = @PhaseGroup and Phase = @phase
   if @@rowcount=0
       begin
       select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@jcco
       if @@rowcount=0
           begin
           select @msg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
           goto bspexit
           end
   
       if @validphasechars=0
           begin
           select @msg = 'Missing Phase', @rcode = 1
           goto bspexit
           end
   
       -- get the mask for bPhase
       select @inputmask=InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
   
       -- format valid portion of phase
       select @pphase=substring(@phase,1,@validphasechars) + '%'
       select TOP 1 @msg = Description
       from JCPM with (nolock) where PhaseGroup = @PhaseGroup and Phase like @pphase
       Group By PhaseGroup, Phase, Description
       if @@rowcount = 0
           begin
           select @msg = 'Phase not setup in Phase Master.', @rcode = 1
           goto bspexit
           end
       end
   
   
   if @job is not null
       begin
       select @msg = isnull(Description,@msg)
       from JCJP where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGroup and Phase=@phase
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPMValUseValidChars] TO [public]
GO
