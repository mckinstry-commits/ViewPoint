SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVCOSTTYPE    Script Date: 8/28/99 9:35:07 AM ******/
CREATE    PROC [dbo].[bspJCVCOSTTYPE]
/***********************************************************
* CREATED: JE   11/21/96
* LAST MODIFIED: GG 06/17/99
*		JE 07/07/99 - check CT between 0 to 255
*		LM 10/21/99 - added begin, end and an else in the check for numeric, was trying to
*					execute code even if it wasn't a numeric passed in.  issue 5147
*		GG 11/08/99 - added Job to error message
*		DANF 03/16/00 Changed valid part of phase validation.
*		EN 4/21/00 - error message regarding Job/Phase/Cost Type combo was including '%' after the phase
*		GR 11/01/00 - fixed to display stored procedure in error message only when rcode=1
*		RM 02/28/01 - Changed @Desc to char(10)
*		GF 09/27/2001 - Changed validation from Subcontracts and materials to
*					use company parameters for validation.
*		TV - 23061 added isnulls
*		EN 9/20/05 - #29634 modified error messages generated when an invalid phase/cost type combination is discovered
*		TJL 01/29/09 - Issue #130083, CostType no longer clears on F3 default if Job and Phase missing.
*		GF 07/21/2009 - issue #129667 - added material option 3
*		TJL 09/23/09 - Issue #134973, Adding PhaseGroup to 'where clause' when selecting from bJCCH speeds up operation
*		EN 1/18/2010 #136587  clarify the 'Inactive Cost Type' message to specify Cost Type, JC Co, Job and Phase
*		AMR 01/17/11 - #142350, changing PhaseGroup Output Param
*
*
*
* USAGE:
* Validates a JC Job/Phase/CostType combination.
*
* Valid combinations that do not exist in bJCJP are added
* via the insert trigger on bJCCD.
*
* It will validate by first checking in JCCT then JCCH, if Phases are
* not 'locked', then check valid portion of phase in JCJP, JCPM, and
* finally, check valid portion of phase in JCPM
*
* PM Modification:
* Override flag may be set to 'P'.  This will cause the Cost Type to only be validated in
* JCCT and if in JCCH, will not care if it is inactive.  It will also act like lock phases override is 'Y'.
* Override flag may be set to 'S'. Used from PMSubcontract and PMSLItems to validate cost type to JCCH
*                                  using the PM company subcontract option. If 1 works like locked phases.
* Override flag may be set to 'M'. Used from PMMaterial and PMPOItems to validate cost type to JCCH
*                                  using the PM company material option. If 1 works like locked phases.
*
* INPUT PARAMETERS
*    @jcco       JC Company
*    @job        Job
*	   @phasegroup bGroup
*    @phase      Phase
*    @costtype   Cost type - may be passed as cost type number and or abbrevation
*    @override   Optional - if 'Y', override 'lock phases' flag in Job Master
*
* OUTPUT PARAMETERS
*    @pphase           valid portion of phase (may not match passed phase)
*    @PhaseGroupOUT       needed for adding a cost type
*    @desc             ten character abbreviation
*    @billflag         bill flag from JCCH or JCPC.
*    @um               unit of measure from JCCH or JCPC.
*    @itemunitflag     item unit flag from JCCH or JCPC.
*    @phaseunitflag    phase unit flag from JCCH or JCPC.
*    @JCCHexists       Y=JCCH already exists no need to add it.
*    @costtypeout      numeric cost type
*    @msg              cost type abbreviation, or error message.
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
  @costtype varchar(10) = NULL,
  @override char(1) = 'N',
  @PhaseGroupOUT tinyint = NULL OUTPUT,
  @pphase bPhase = NULL OUTPUT,
  @desc varchar(255) = NULL OUTPUT,
  @billflag char(1) = NULL OUTPUT,
  @um bUM = NULL OUTPUT,
  @itemunitflag bYN = NULL OUTPUT,
  @phaseunitflag bYN = NULL OUTPUT,
  @JCCHexists char(1) = NULL OUTPUT,
  @costtypeout bJCCType = NULL OUTPUT,
  @msg varchar(255) = NULL OUTPUT
)
AS 
SET nocount ON

declare @rcode int, @validphasechars int, @lockphases bYN, @active bYN, @inputmask varchar(30),
       @rowcount int, @slct1option tinyint, @mtct1option tinyint

select @rcode = 0, @JCCHexists = 'N'

if @jcco is null
	begin
	select @desc = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

------------- Issue #130083: Move to later in procedure
-- When ready, REM this code per Issue #130083:  Move code after CostType Switcheroo and validation code 
--if @job is null
--   	begin
--   	select @desc = 'Missing Job!', @rcode = 1
--   	goto bspexit
--   	end
--if @phase is null
--   	begin
--   	select @desc = 'Missing Phase!', @rcode = 1
--   	goto bspexit
--   	end

if @costtype is null
	begin
	select @desc = 'Missing Cost Type!', @rcode = 1
	goto bspexit
	end
   
-- get cost type header options from PMCO
select @slct1option=SLCT1Option, @mtct1option=MTCT1Option
from bPMCO with (nolock) where PMCo = @jcco

/* PHASEGROUP VALIDATION CHECKS */   
-- validate phase group from bHQGP
select @PhaseGroupOUT = PhaseGroup from bHQGP with (nolock) 
JOIN bHQCO with (nolock) ON bHQCO.HQCo = @jcco and bHQCO.PhaseGroup = bHQGP.Grp
if @PhaseGroupOUT is null
   begin
   select @desc = 'Phase Group: ' + isnull(convert(varchar(3),@PhaseGroupOUT),'') + ' is invalid!', @rcode = 1
   goto bspexit
   end
  
-- get Phase Group
select @PhaseGroupOUT = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
if @@rowcount <> 1
   begin
   select @desc = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
   goto bspexit
   end
  
--Issue 17738
if @PhaseGroup<>@PhaseGroupOUT
	begin 
	select @desc = 'Phase Group ' + isnull(convert(varchar(3), @PhaseGroup),'') + ' for HQ Company ' 
	+ convert(varchar(3),@jcco) + ' does not match Phase Group ' + isnull(convert(varchar(3), @PhaseGroupOUT),''), @rcode = 1
	   goto bspexit
	end
  
/* COSTYPE SWITCHEROO AND VALIDATION */
-- if cost type is numeric then try to find
if isnumeric(@costtype) = 1
  	begin
	if (select convert(int,convert(float, @costtype))) <0 or (select convert(int,convert(float, @costtype)))>255
  		begin
   		select @desc = 'CostType must be between 0 and 255.', @rcode = 1
   		goto bspexit
		end
  	else
  		begin
  		select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
  		from bJCCT with (nolock) 
  		where PhaseGroup = @PhaseGroupOUT and CostType = convert(int,convert(float, @costtype))
  		end
  	end
  
-- if not numeric or not found try to find as Abbreviation
if @@rowcount = 0
   	begin
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
   	from bJCCT with (nolock) 
   	where PhaseGroup = @PhaseGroupOUT and Abbreviation like @costtype + '%'
   	if @@rowcount = 0
   		begin
   		select @desc = 'JC Cost Type ' + isnull(@costtype,'') + ' not setup in Cost Type Master!', @rcode = 1
   		goto bspexit
   		end
  	end

-- REM'D per Issue #130083: Already accomplished above	  
-- validate cost type in JC Cost Type master
--select @desc = Abbreviation
--from bJCCT with (nolock) where PhaseGroup = @PhaseGroupOUT and CostType = @costtypeout
--if @@rowcount = 0
--	begin
--	select @desc = 'Cost Type ' + isnull(convert(varchar(3),@costtypeout),'') + ' not setup in JC Cost Type Master!', @rcode=1
--	goto bspexit
--	end

/* Issue #130083: CONTINUE WITH ADDITIONAL CHECKS BASED UPON A VALID JOB, PHASE, AND COSTTYPE */
-- Inputs for @job and @phase get tested here rather than at beginning of procedure to allow 
-- CostType switcheroo to do its job first.  In this way user can F3 a CostType without
-- also having to F3 Job and Phase.  Validation will catch Job/Phase/CostType imcompatabilties
-- long before record gets saved.
if @job is null
	begin
   	select @desc = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
if @phase is null
   	begin
   	select @desc = 'Missing Phase!', @rcode = 1
   	goto bspexit
   	end
 
-- get valid portion of phase
select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo = @jcco
if @@rowcount = 0
  	begin
  	select @desc = 'JC Co# ' + isnull(convert(varchar(3),@jcco),'') + ' not setup in JC Company Master!', @rcode = 1
  	goto bspexit
  	end
  
-- get 'locked phases flag' from JC Job Master */
select @lockphases = LockPhases from bJCJM with (nolock) where JCCo = @jcco and Job = @job
if @@rowcount <> 1
  	begin
  	select @desc = 'Job: ' + isnull(@job,'') + ' not setup in Job Master!', @rcode = 1
  	goto bspexit
  	end

-- Check full phase in JC Cost Header
select @pphase = Phase, @um = UM, @active = ActiveYN, @billflag = BillFlag,
	@itemunitflag = ItemUnitFlag, @phaseunitflag = PhaseUnitFlag
from bJCCH with (nolock) where JCCo = @jcco and Job = @job and PhaseGroup = @PhaseGroupOUT and Phase = @phase and CostType = @costtypeout
select @rowcount = @@rowcount
if @override not in ('P','S','M') and @active = 'N'
  	begin
  	select @desc = 'Inactive Cost Type ' + convert(varchar,@costtypeout) + ' for JC Co ' + convert(varchar,@jcco) + ', Job' + @job + ', Phase ' + @phase + '!', @rcode=1
  	select @JCCHexists = 'Y'
  	goto bspexit
  	end

if @rowcount = 1
	begin
  	select @rcode = 0, @JCCHexists = 'Y'
  	goto bspexit
  	end
   
-- check SLCT1Option if (1) and @override = 'S' must be exact match
if isnull(@slct1option,2) = 1 and @override = 'S'
  	begin
  	select @desc = 'Phase/Cost Type is not in JCCH and PM company subcontract option is set to one.', @rcode = 1
  	goto bspexit
  	end
   
-- check MTCT1Option if (1) and @override = 'M' must be exact match
if isnull(@mtct1option, 3) = 1 and @override = 'M'
  	begin
  	select @desc = 'Phase/Cost Type is not in JCCH and PM company material option is set to one.', @rcode = 1
  	goto bspexit
  	end
   
if @lockphases = 'Y' and @override not in ('Y','P','S','M')
  	begin
  	-- Phase and Cost Types are locked for this Job - no override
  	select @desc = 'Phase: ' + isnull(@phase,'') + ' Cost Type:'+ isnull(convert(varchar(3),@costtypeout),'') + ' not setup on Job: ' + isnull(@job,''), @rcode = 1
  	goto bspexit
  	end
  
if isnull(@validphasechars,0) = 0 goto skipvalidportion

-- get the mask for bPhase
select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'

-- format valid portion of phase
select @pphase = substring(@phase,1,@validphasechars) + '%'
   
-- Check valid portion of phase in JC Cost Header */
select Top 1 @pphase = Phase, @um = UM, @billflag = BillFlag, @itemunitflag = ItemUnitFlag, @phaseunitflag = PhaseUnitFlag
from bJCCH with (nolock) 
where JCCo = @jcco and Job = @job and Phase like @pphase and CostType = @costtypeout
Group By JCCo, Job, Phase, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
if @@rowcount = 1
  	begin
  	select @rcode = 0
  	goto bspexit
  	end
   
skipvalidportion:
-- Check full phase in JC Phase Cost Types
select @pphase=Phase, @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
from bJCPC with (nolock) 
where PhaseGroup = @PhaseGroupOUT and Phase = @phase and CostType = @costtypeout
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
   
   	select Top 1 @pphase = Phase, @um = UM, @billflag = BillFlag, @itemunitflag = ItemUnitFlag, @phaseunitflag = PhaseUnitFlag
   	from bJCPC with (nolock) 
   	where PhaseGroup = @PhaseGroupOUT and Phase like @pphase and CostType = @costtypeout
	Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
   	if @@rowcount = 1
  		begin
  		select @rcode = 0
  		goto bspexit
  		end
   	end
  
if @override not in ('P','S','M')
  	begin
  	select @rcode = 1
  	select @desc = case @lockphases
  		when 'Y' then 'Job: ' + isnull(@job,'') + ' Phase: ' + isnull(@phase,'') + ' Cost Type: ' + isnull(convert(varchar(3),@costtypeout),'') + ' - Phase/Cost Type combination has not been set up on the Job.'
  		when 'N' then 'Job: ' + isnull(@job,'') + ' Phase: ' + isnull(@phase,'') + ' Cost Type: ' + isnull(convert(varchar(3),@costtypeout),'') + ' - Phase/Cost Type combination has not been set up in either Phase Master or Job Phases.'
  		end
  	end 
  
bspexit:
if @rcode = 1 select @msg = @desc
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPE] TO [public]
GO
