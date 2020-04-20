SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vfPRTSUMforPhase]
(@prco bCompany, @jcco bCompany = null, @job bJob = null, @phase bPhase = null, 
	@phasegroup tinyint, @costtype bJCCType)
RETURNS bUM
AS
BEGIN
/*******************************
*
*		Created By:  MarkH 6/5/07
*		Modified By: markh 04/01/09 - Issue 132377
*
*		Usage: 
*		Get the Unit of Measure for a Phase to use in PRCrewTSEntry
*
********************************/

	declare @um bUM, @pphase bPhase, @validphasechars int, /*@crewregec bEDLCode, @costtype bJCCType,*/ 
			@rowcount int, @inputmask varchar(30)

    -- get valid portion of phase
       select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo = @jcco
       if @@rowcount = 0
       	begin
       	goto bspexit
       	end

--Issue 132377 - passing in Cost Type.
--     select @crewregec=CrewRegEC from PRCO where PRCo=@prco
--     select @costtype=JCCostType from PREC where PRCo=@prco and EarnCode=@crewregec

       -- Check full phase in JC Cost Header
       select @pphase = Phase, @um = UM
       from bJCCH with (nolock) where JCCo = @jcco and Job = @job and Phase = @phase and CostType = @costtype
       select @rowcount = @@rowcount
       if @rowcount = 1
       	begin
       	goto bspexit
       	end
        
       if isnull(@validphasechars,0) = 0 goto skipvalidportion
        
       -- get the mask for bPhase
       select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
        
       -- format valid portion of phase
       select @pphase = substring(@phase,1,@validphasechars) + '%'
        
       -- Check valid portion of phase in JC Cost Header
       select Top 1 @pphase = Phase, @um = UM
       from bJCCH with (nolock) 
       where JCCo = @jcco and Job = @job and Phase like @pphase and CostType = @costtype
       Group By JCCo, Job, Phase, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
       if @@rowcount = 1
       	begin
       	goto bspexit
       	end
        
       skipvalidportion:
       -- Check full phase in JC Phase Cost Types
       select @pphase=Phase, @um=UM
       from bJCPC with (nolock) 
       where PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype
       if @@rowcount = 1
       	begin
       	goto bspexit
       	end
       
       -- Check valid portion
       if @validphasechars > 0
       	begin
       	-- Check partial phase in JC Phase Cost Types
       	select @pphase = substring(@phase,1,@validphasechars) + '%'
        
        	select Top 1 @pphase = Phase, @um = UM
        	from bJCPC with (nolock) 
        	where PhaseGroup = @phasegroup and Phase like @pphase and CostType = @costtype
           Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
        	if @@rowcount = 1
       			begin
	       		goto bspexit
       			end
        end

 bspexit:
    
	RETURN @um

END

GO
GRANT EXECUTE ON  [dbo].[vfPRTSUMforPhase] TO [public]
GO
