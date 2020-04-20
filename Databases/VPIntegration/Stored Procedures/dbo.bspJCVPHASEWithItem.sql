SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVPHASEWithItem    Script Date: 8/28/99 9:35:08 AM ******/
CREATE  procedure [dbo].[bspJCVPHASEWithItem]
/***********************************************************
* CREATED BY: GF 08/03/98
* MODIFIED By : DANF 03/16/00 Change valid part of phase validation
*				TV - 23061 added isnulls
*				CHS	03/01/2009 - #120115
*
* USAGE: This is a copy of bspJCVPHASE, verify any changes are in both procedures.
* Standard Phase validation procedure used from programs where the contract item has
* already been assigned.  Called from forms and procedures (normally change orders)
* to check a JC Phase.  Assumes the Job, Contract, and Contract item have already been validated.
* Validates as follows:
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
*    @contract     Valid contract
*    @item	    Valid contract item
*    @phase        Phase to validate
*    @override     Optional - if set to 'Y' will override 'lock phases' flag in bJCJM
*
* OUTPUT PARAMETERS
*    @pphase       valid portion of phase (may not match passed phase)
*    @desc         phase description
*    @PhaseGroup   phase group from bHQCO
*    @pcontract     contract from JCJM
*    @pitem         contract item from JCCI as validated
*    @dept         Job Cost department, specified in either contract or item file.
*    @ProjMin%     Project minimum percent
*    @JCJPexists   Full Job/Phase was found='Y'
*    @msg          Phase description, or error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = null, 
@job bJob = null, 
@phase bPhase = null, 
@contract bContract = null,
@item bContractItem = null, 
@override bYN = 'N',

@pphase bPhase = null output, 
@desc varchar(60) = null output, 
@PhaseGroup tinyint = null output,
@jcontract bContract = null output, 
@pitem bContractItem = null output, 
@dept bDept = null output,
@projminpct real = null output, 
@JCJPexists varchar(1) = null output, 
@inscode bInsCode = null output, 
@msg varchar(255) = null output)

   as
   set nocount on
   
   declare @rcode int, @validphasechars int, @lockphases bYN, @active bYN, @inputmask varchar(30), @rowcount int
   
   select @rcode = 0, @dept=null, @JCJPexists='N'
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
   if @contract is null
   	begin
   	select @desc = 'Missing Contract!', @rcode = 1
   	goto bspexit
   	end
   if @item is null
   	begin
   	select @desc = 'Missing Contract Item!', @rcode = 1
   	goto bspexit
   	end
   if @phase is null
   	begin
   	select @desc = 'Missing Phase!', @rcode = 1
   
   	goto bspexit
   	end
   
   -- validate JC Company -  get valid portion of phase code
   select @validphasechars = ValidPhaseChars from JCCO with (nolock) where JCCo = @jcco
   if @@rowcount = 0
       begin
       select @desc = 'Invalid Job Cost Company!', @rcode = 1
       goto bspexit
       end
   
   -- get Phase Group
   select @PhaseGroup = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
   if @@rowcount = 0
       begin
       select @desc = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
       goto bspexit
       end
   
   -- validate Job - get 'locked phases' flag
   select @contract = Contract, @lockphases = LockPhases
   from JCJM with (nolock) where JCCo = @jcco and Job = @job
   if @@rowcount = 0
       begin
       select @desc = 'Job ' + isnull(@job,'') + ' not found!', @rcode = 1
       goto bspexit
       end
   
   -- first check Job Phases - exact match
   select @desc = Description, @pphase = Phase, @pitem = Item, @active = ActiveYN, @projminpct = ProjMinPct, @inscode=InsCode
   from JCJP with (nolock) 
   where JCCo = @jcco and Job = @job and Phase = @phase
   if @@rowcount = 1
       begin
       select @JCJPexists = 'Y'
       if @active = 'Y' goto getjcdept   -- Phase is on file and active
       select @desc = 'Phase ' + isnull(@phase,'') + ' is inactive!', @rcode = 1  -- Phase is on file, but inactive
       goto bspexit
       end
   
   -- check 'locked phases' and override
   if @lockphases = 'Y' and @override <> 'Y'
       begin
       select @desc = 'Phase ' + isnull(@phase,'') + ' is invalid!', @rcode = 1   -- No new Phases allowed
       goto bspexit
       end
   
   -- check for a valid portion
   if isnull(@validphasechars,0) = 0 goto skipvalidportion
   
   -- get the format for datatype 'bPhase'
   select @inputmask = InputMask
   from DDDTShared with (nolock) where Datatype = 'bPhase'
   if @@rowcount = 0
       begin
       select @desc = 'Missing (bPhase) datatype in DDDTShared!', @rcode = 1    -- should always exist
       goto bspexit
       end
   
   -- format valid portion of Phase
   select @pphase = substring(@phase,1,@validphasechars) + '%'
   
   -- check valid portion of Phase in Job Phase table
   select Top 1 @desc = Description, @pphase = Phase, @projminpct = ProjMinPct
   from JCJP with (nolock) 
   where JCCo = @jcco and Job = @job and Phase like @pphase
   Group By JCCo, Job, Phase, Description, ProjMinPct
   
   skipvalidportion:
   -- full match in Phase Master will override description from partial match in Job Phase
   select @desc = isnull(isnull(Description,@desc),''), @pphase = isnull(Phase,@phase), @projminpct = ProjMinPct
   from JCPM with (nolock) 
   where PhaseGroup = @PhaseGroup and Phase = @phase
   -- if we've got a Description we've found a match 
   if @@rowcount<>0
       begin
       select @rcode = 0
       goto getjcdept
       end
   
   -- check Phase Master using valid portion
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
   -- we are out of places to check
   select @desc = 'Phase ' + isnull(@phase,'') + ' not on file!', @rcode = 1goto bspexit
   
   getjcdept:  -- get JC Department from Contract Item
   select @dept = Department
   from bJCCI with (nolock) where JCCo = @jcco and Contract = @contract and Item = @item
   if @@rowcount = 0
   	begin
   	select @desc = 'Contract Item ' + isnull(@item,'') + ' not set up!', @rcode = 1
   	end
   
   
   
   
   bspexit:
       select @msg = @desc
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCVPHASEWithItem] TO [public]
GO
