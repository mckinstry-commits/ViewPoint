SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVCOSTTYPEForTSSend    Script Date: 8/28/99 9:35:07 AM ******/
CREATE        PROC [dbo].[bspJCVCOSTTYPEForTSSend]
	/***********************************************************
	* CREATED: EN 7/24/03
	* LAST MODIFIED: TV - 23061 added isnulls
	*				EN 11/30/04 issue 26090 don't check for phases associated with locked jobs
	*			AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
	*
	* USAGE:
	* Validates a JC Job/Phase/CostType combination for Crew Timesheet Send.
	*
	* Valid combinations that do not exist in bJCJP are added
	* via the insert trigger on bJCCD.
	*
	* It will validate by first checking in JCCT then JCCH, if Phases are
	* not 'locked', then check valid portion of phase in JCJP, JCPM, and
	* finally, check valid portion of phase in JCPM
	*
	*
	* INPUT PARAMETERS
	*    @jcco       JC Company
	*    @job        Job
	*	@PhaseGroup bGroup
	*    @phase      Phase
	*    @CostType   Cost type - may be passed as cost type number and or abbrevation
	*	@actualdate 
	*
	* OUTPUT PARAMETERS
	*	@um			unit of measure from JCCH or JCPC
	*    @projected	projected amount from JCCD
	*	@actual		actual amount from JCCD
	*    @msg        cost type abbreviation, or error message.
	*
	* RETURN VALUE
	*   0         success
	*   1         Failure
	*****************************************************/
(
  @jcco bCompany = NULL,
  @job bJob = NULL,
  @PhaseGroup bGroup,
  @phase bPhase = NULL,
  @CostType varchar(10) = NULL,
  @actualdate bDate = 0,
  @um bUM = NULL OUTPUT,
  @projected bUnits = 0 OUTPUT,
  @estimated bUnits = 0 OUTPUT,
  @actual bUnits = 0 OUTPUT,
  @plugged bYN OUTPUT,
  @msg varchar(255) = NULL OUTPUT
)
AS 
SET nocount ON
	--#142350 - renaming @phasegroup and @costtype
    DECLARE @rcode int,
			@validphasechars int,
			@lockphases bYN,
			@active bYN,
			@inputmask varchar(30),
			@rowcount int,
			@slct1option tinyint,
			@mtct1option tinyint,
			@PhaseGrp tinyint,
			@pphase bPhase,
			@CostTyp bJCCType,
			@errmsg varchar(255)
    
        select @rcode = 0
        
        if @jcco is null
        	begin
        	select @errmsg = 'Missing JC Company!', @rcode = 1
        	goto bspexit
        	end
        if @job is null
        	begin
        	select @errmsg = 'Missing Job!', @rcode = 1
        	goto bspexit
        	end
        if @phase is null
        	begin
        	select @errmsg = 'Missing Phase!', @rcode = 1
        	goto bspexit
        	end
        if @CostType is null
        	begin
        	select @errmsg = 'Missing Cost Type!', @rcode = 1
        	goto bspexit
        	end
        
        -- get cost type header options from PMCO
        select @slct1option=SLCT1Option, @mtct1option=MTCT1Option
        from PMCO with (nolock) where PMCo = @jcco
        
       -- validate phase group from bHQGP
       select @PhaseGrp = PhaseGroup from bHQGP with (nolock) 
       JOIN bHQCO with (nolock) ON bHQCO.HQCo = @jcco and bHQCO.PhaseGroup = bHQGP.Grp
       if @PhaseGrp is null
            begin
            select @errmsg = 'Phase Group: ' + isnull(convert(varchar(3),@PhaseGrp),'') + ' is invalid!', @rcode = 1
            goto bspexit
            end
       
       -- get Phase Group
       select @PhaseGrp = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
        if @@rowcount <> 1
            begin
            select @errmsg = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
            goto bspexit
            end
       
       --Issue 17738
       if @PhaseGroup<>@PhaseGrp
       	begin
       	select @errmsg = 'Phase Group ' + isnull(convert(varchar(3), @PhaseGrp),'') + ' for HQ Company ' 
       	+ convert(varchar(3),@jcco) + ' does not match Phase Group ' + isnull(convert(varchar(3), @PhaseGroup),''), @rcode = 1
            goto bspexit
       	end
       
       -- if cost type is numeric then try to find
       if isnumeric(@CostType) = 1
       	begin
           if (select convert(int,convert(float, @CostType))) <0 or (select convert(int,convert(float, @CostType)))>255
       		begin
        		select @errmsg = 'CostType must be between 0 and 255.', @rcode = 1
        		goto bspexit
         		end
       	else
       		begin
       		select @CostTyp = CostType, @msg = Description
       		from bJCCT with (nolock) 
       		where PhaseGroup = @PhaseGrp and CostType = convert(int,convert(float, @CostType))
       		end
       	end
       
       -- if not numeric or not found try to find as Sort Name
       if @@rowcount = 0
        	begin
           select @CostTyp = CostType, @msg = Description
        	from bJCCT with (nolock) 
        	where PhaseGroup = @PhaseGrp and Abbreviation like @CostType + '%'
        	if @@rowcount = 0
        		begin
        		select @errmsg = 'JC Cost Type ' + isnull(@CostType,'') + ' not setup in Cost Type Master!', @rcode = 1
        		goto bspexit
        		end
       	end
       
       -- get valid portion of phase
       select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo = @jcco
       if @@rowcount = 0
       	begin
       	select @errmsg = 'JC Co# ' + isnull(convert(varchar(3),@jcco),'') + ' not setup in JC Company Master!', @rcode = 1
       	goto bspexit
       	end
       
       -- get 'locked phases flag' from JC Job Master */
       select @lockphases = LockPhases from bJCJM with (nolock) where JCCo = @jcco and Job = @job
       if @@rowcount <> 1
       	begin
       	select @errmsg = 'Job: ' + isnull(@job,'') + ' not setup in Job Master!', @rcode = 1
       	goto bspexit
       	end
       
       -- validate cost type in JC Cost Type master
       select @rowcount=count(*) from bJCCT with (nolock) where PhaseGroup = @PhaseGrp and CostType = @CostTyp
       if @rowcount = 0
       	begin
       	select @errmsg = 'Cost Type ' + isnull(convert(varchar(3),@CostTyp),'') + ' not setup in JC Cost Type Master!', @rcode=1
       	goto bspexit
       	end
        
       -- Check full phase in JC Cost Header
       select @pphase = Phase, @um = UM, @active = ActiveYN, @plugged = Plugged
       from bJCCH with (nolock) where JCCo = @jcco and Job = @job and Phase = @phase and CostType = @CostTyp
       select @rowcount = @@rowcount
       if @active = 'N'
       	begin
       	select @errmsg = 'Inactive Cost Type!', @rcode=1
       	goto bspexit
       	end
       if @rowcount = 1
       	begin
       	select @rcode = 0
       	goto bspexit
       	end
        
   --    if @lockphases = 'Y' --this section commented out for issue 26090
   --    	begin
   --    	-- Phase and Cost Types are locked for this Job - no override
   --    	select @errmsg = 'Phase: ' + isnull(@phase,'') + ' Cost Type:'+ isnull(convert(varchar(3),@CostTyp),'') + ' not setup on Job: ' + isnull(@job,''), @rcode = 1
   --    	goto bspexit
   --    	end
       
       if isnull(@validphasechars,0) = 0 goto skipvalidportion
        
       -- get the mask for bPhase
       select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
        
       -- format valid portion of phase
       select @pphase = substring(@phase,1,@validphasechars) + '%'
        
       -- Check valid portion of phase in JC Cost Header
       select Top 1 @pphase = Phase, @um = UM
       from bJCCH with (nolock) 
       where JCCo = @jcco and Job = @job and Phase like @pphase and CostType = @CostTyp
       Group By JCCo, Job, Phase, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
       if @@rowcount = 1
       	begin
       	select @rcode = 0
       	goto bspexit
       	end
        
       skipvalidportion:
       -- Check full phase in JC Phase Cost Types
       select @pphase=Phase, @um=UM
       from bJCPC with (nolock) 
       where PhaseGroup = @PhaseGrp and Phase = @phase and CostType = @CostTyp
       if @@rowcount = 1
       	begin
       	select @rcode = 0
       	goto bspexit
       	end
       
       -- Check valid portion
       if @validphasechars > 0
       	begin
       	-- Check partial phase in JC Phase Cost Types
       	select @pphase = substring(@phase,1,@validphasechars) + '%'
        
        	select Top 1 @pphase = Phase, @um = UM
        	from bJCPC with (nolock) 
        	where PhaseGroup = @PhaseGrp and Phase like @pphase and CostType = @CostTyp
           Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
        	if @@rowcount = 1
       		begin
       		select @rcode = 0
       		goto bspexit
       		end
        	end
       
       	select @rcode = 1
       	select @errmsg = 'Phase does not exist!'
       		
      
       
bspexit:
	if @rcode = 0
		begin
		select @projected=isnull(sum(ProjUnits),0), @estimated=isnull(sum(EstUnits),0), @actual=isnull(sum(ActualUnits),0)
		from bJCCD with (nolock) 
		where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGrp and Phase=@phase and CostType=@CostType and 
		UM=@um and ActualDate < = convert(smalldatetime, convert(varchar(11),@actualdate,1),1)
		end

	if @rcode = 1 select @msg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPEForTSSend] TO [public]
GO
