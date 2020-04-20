SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVPHASEForJCJP    Script Date: 8/28/99 9:35:08 AM ******/
CREATE procedure [dbo].[bspJCVPHASEForJCJP]
/***********************************************************
* CREATED BY: SE   11/10/96
* MODIFIED By : GG 07/30/98
* MODIFIED By : GH 02/17/99 Changed Error Message For Locked Phases Call #1023360
* MODIFIED By : LM 08/17/99 Changed to bspJCVPHASEForJCJP from bspJCVPHASE because when in JCJP,
*                           phase can be inactive - call 1036362
*               DANF 03/16/00 Change valid part of phase validation.
*				TV - 23061 added isnulls
*				GF - #24398 separate out the item select for valid part phase to use min() backed out per gary and carol
*				GF - #127??? add phase original total as output for use in PM 6.x.
*				CHS	03/01/2009 - #120115
*
* USAGE:
* Standard Phase validation procedure.  Called from numerous forms
* and procedures to check a JC Phase.  Assumes the Job has already
* been validated.  Validates as follows:
* 1st - Checks for exact match in Job Phase table
*      If found, must be active, else rejected.
* 2nd - Check valid portion in Job Phase table if phases have not
*      been 'locked', or override flag is set.
* 3rd - Checks Phase Master for exact match - if exists, use description, etc.
* 4th - Checks Phase Master on validated portion
*
* A Phase that does not exist in bJCJP will be added by the insert trigger on bJCCD.
*
* INPUT PARAMETERS
*    @jcco         Job Cost Company
*    @job          Valid job
*    @phase        Phase to validate
*    @override     Optional - if set to 'Y' will override 'lock phases' flag in bJCJM
*
* OUTPUT PARAMETERS
*    @pphase       valid portion of phase (may not match passed phase)
*    @desc         phase description
*    @PhaseGroup   phase group from bHQCO
*    @contract     contract from JCJM
*    @item         contract item from JCCI as validated
*    @dept         Job Cost department, specified in either contract or item file.
*    @ProjMin%     Project minimum percent
*    @JCJPexists   Full Job/Phase was found='Y'
*    @msg          Phase description, or error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = null, @job bJob = null, @phase bPhase = null, @override bYN = 'N',
 @pphase bPhase = null output, @desc varchar(255) = null output, @PhaseGroup tinyint = null output,
 @contract bContract = null output, @item bContractItem = null output, @dept bDept = null output,
 @projminpct real = null output, @JCJPexists varchar(1) = null output, 
 @phasetotal numeric(14,2) = 0 output, @inscode bInsCode = null output, @msg varchar(255) = null output)

as
set nocount on

declare @rcode int, @validphasechars int, @lockphases bYN, @active bYN, @inputmask varchar(30), @rowcount int

select @rcode = 0, @item=null, @dept=null, @JCJPexists='N'

if @jcco is null
   	begin
   	select @desc = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

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

-- -- -- get phase total
select @phasetotal = isnull(sum(OrigCost),0) 
from JCCH (nolock) where JCCo=@jcco and Job=@job and Phase=@phase

-- -- -- validate JC Company -  get valid portion of phase code
select @validphasechars = ValidPhaseChars from JCCO with (nolock) where JCCo = @jcco
if @@rowcount = 0
       begin
       select @desc = 'Invalid Job Cost Company!', @rcode = 1
       goto bspexit
       end

-- -- -- get Phase Group
select @PhaseGroup = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
if @@rowcount = 0
       begin
       select @desc = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
       goto bspexit
       end

-- -- -- validate Job - get 'locked phases' flag
select @contract = Contract, @lockphases = LockPhases
from JCJM with (nolock) where JCCo = @jcco and Job = @job
if @@rowcount = 0
       begin
       select @desc = 'Job ' + isnull(@job,'') + ' not found!', @rcode = 1
       goto bspexit
       end

-- -- -- first check Job Phases - exact match
select @desc = Description, @pphase = Phase, @item = Item, @active = ActiveYN, @projminpct = ProjMinPct, @inscode=InsCode
from JCJP with (nolock) 
where JCCo = @jcco and Job = @job and Phase = @phase
if @@rowcount = 1
       begin
       select @JCJPexists = 'Y'
       goto getjcdept  -- for JCJP, the phase can be inactive, so skip this part
       end

-- -- -- check 'locked phases' and override
if @lockphases = 'Y' and @override <> 'Y'
       begin
       select @desc = 'Locked Phase ' + isnull(@phase,'') + ' is not on job!', @rcode = 1   -- No new Phases allowed
       goto bspexit
       end

-- -- -- check for a valid portion
if isnull(@validphasechars,0) = 0 goto skipvalidportion
-- -- -- get the format for datatype 'bPhase'
select @inputmask = InputMask
from DDDTShared with (nolock) where Datatype = 'bPhase'
if @@rowcount = 0
       begin
       select @desc = 'Missing (bPhase) datatype in DDDTShared!', @rcode = 1    -- should always exist
       goto bspexit
       end

-- -- -- format valid portion of Phase
select @pphase = substring(@phase,1,@validphasechars) + '%'

-- check valid portion of Phase in Job Phase table
select Top 1 @desc = Description, @pphase = Phase, @item = Item, @projminpct = ProjMinPct
from bJCJP with (nolock)
where JCCo = @jcco and Job = @job and Phase like @pphase
Group By JCCo, Job, Phase, Item, Description, ProjMinPct

-- -- -- -- -- separate out the contract item select so that we can get the min(Item)
-- -- -- select @item = min(Item) from bJCJP  where JCCo = @jcco and Job = @job and Phase like @pphase

skipvalidportion:
-- -- -- full match in Phase Master will override description from partial match in Job Phase
select @desc = isnull(isnull(Description,@desc),''), @pphase = isnull(Phase,@phase), @projminpct = ProjMinPct
from JCPM with (nolock) 
where PhaseGroup = @PhaseGroup and Phase = @phase
-- -- -- if we've got a Description we've found a match
if @@rowcount<>0
       begin
       select @rcode = 0
       goto getjcdept
       end

-- -- -- check Phase Master using valid portion
if @validphasechars > 0
       begin
       select @pphase = substring(@phase,1,@validphasechars) + '%'
       select Top 1 @desc = Description, @pphase = Phase, @projminpct = ProjMinPct
       from bJCPM with (nolock) 
       where PhaseGroup = @PhaseGroup and Phase like @pphase
       Group By PhaseGroup, Phase, Description, ProjMinPct
       if @@rowcount = 1
   	   begin
   	   select @rcode = 0
   	   goto getjcdept
   	   end
       end

-- -- -- we are out of places to check
select @desc = 'Phase ' + isnull(@phase,'') + ' not on file!', @rcode = 1
goto bspexit
   

getjcdept: 
-- -- -- get JC Department from Contract Master or Item
if @item is null
   	begin
   	-- -- -- get first Item on Contract
   	select @item = min(Item) from bJCCI with (nolock) where JCCo = @jcco and Contract = @contract
   	end

if @item is null
   	begin
   	-- -- -- no Items on the Contract, use Department from Contract Master
   	select @dept = Department from bJCCM where JCCo = @jcco and Contract = @contract
   	if @@rowcount = 0
   		begin
   		select @desc = 'Contract ' + isnull(@contract,'') + ' not setup!', @rcode = 1
   		goto bspexit
   		end
   	end
else
   	begin
   	select @dept = Department
   	from bJCCI with (nolock) where JCCo = @jcco and Contract = @contract and Item = @item
   	if @@rowcount = 0
   		begin
   		select @desc = 'Contract Item ' + isnull(@item,'') + ' not set up!', @rcode = 1
   		end
   	end






bspexit:
	select @msg = @desc
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVPHASEForJCJP] TO [public]
GO
