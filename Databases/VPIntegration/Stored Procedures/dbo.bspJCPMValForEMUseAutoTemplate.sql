SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspJCPMValForEMUseAutoTemplate]
    /***********************************************************
     * CREATED BY: JM 11-14-02 - Adapted from bspJCPMVal
     * MODIFIED By : TV - 23061 added isnulls
     *
     * USAGE: Vvalidates JC Phase from Phase Master.according to the section of the Phase per
     *	JCCO.ValidPhaseChars
     * 	An error is returned if any of the following occurs
     * 		No phase passed 
     *		No phase 'section' found in JCPM
     *
     * INPUT PARAMETERS
     *	PhaseGroup  		JC Phase group for this company
     *   	Phase 			Insurance template to validate
     *
     * OUTPUT PARAMETERS
     *   	@msg      		Error message if error occurs otherwise Description of Template description
     * RETURN VALUE
     *   	0         			Success
     *   	1         			Failure
     *****************************************************/ 
    (@emco bCompany,
    @phasegroup tinyint, 
    @phase bPhase = null, 
    @msg varchar(60) output)
    
    as
    set nocount on
    
    declare @inputmask varchar(30), 
   	@jcco bCompany,
   	@pphase bPhase,
   	@rcode int,
    	@validphasechars tinyint,
    	@validphasesection varchar(20)
    
    select @rcode = 0
    
    if @phasegroup is null
    	begin
    	select @msg = 'Missing Phase Group', @rcode = 1
    	goto bspexit
    	end
    if @phase is null
    	begin
    	select @msg = 'Missing Phase', @rcode = 1
    	goto bspexit
    	end
    
   /* Following section copied from bspJCPMValUseValidChars (added selection of JCCo) */
   select @msg = Description from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase = @phase
    /* If exact match not found, search by valid section of the Phase */
   if @@rowcount=0
   	begin
   	select @jcco = JCCo from bEMCO where EMCo = @emco
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
   	select TOP 1 @msg = Description from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase like @pphase
   	Group By PhaseGroup, Phase, Description
   	if @@rowcount = 0
   		begin
   		select @msg = 'Phase not setup in Phase Master.', @rcode = 1
   		goto bspexit
   		end
   	end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPMValForEMUseAutoTemplate] TO [public]
GO
