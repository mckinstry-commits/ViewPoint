SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVPHASE    Script Date: 8/28/99 9:35:07 AM ******/
   CREATE   PROCEDURE [dbo].[bspJCVPHASE]
	/***********************************************************
	* CREATED BY: SE   11/10/96
	* MODIFIED By : GG 07/30/98
	* MODIFIED By : GH 02/17/99 Changed Error Message For Locked Phases Call #1023360
	*             : DANF 03/16/00 Change Valid part of phase validation.
	*				: SR 07/08/02 - Issue 17738 - pass in phasegroup and validate against PhaseGroup from HQCO
	*				: GF 08/08/2002 - Issue 17355 - auto add item enhancement.
	*				: GF 01/13/2004 - issue #23450 - job not found error, related to issue #15363 removed insert
	*					of security from JCJM insert trigger to VB. Will now use bJCJM when override flag is 'Y'.
	*				TV - 23061 added isnulls
	*				GF - #24398 separate out the item select for valid part phase to use min(). backed out per gary and carol
	*				GF 08/12/2008 - issue #129388 added check for override = 'O' which is from JCJP insert trigger.
	*				TRL 05/27/09 - Issue 133733, Added Phase group to where clause in JCJP select statements
	*				EN 3/26/10 #136430  clarify the inactive phase message to specify JC Co and Job
	*				AMR 01/19/11 - #142350, making case insensitive by changing OUTPUT @PhaseGroup var
	*
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
	*    @phasegroup   group to validate against PhaseGroup in HQCO
	*    @override     Optional - if set to 'Y' will override 'lock phases' flag in bJCJM
	*
	* OUTPUT PARAMETERS
	*    @pphase       valid portion of phase (may not match passed phase)
	*    @desc         phase description
	*    @PhaseGroupOUT   phase group from bHQCO
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
(
  @jcco bCompany = NULL,
  @job bJob = NULL,
  @phase bPhase = NULL,
  @phasegroup tinyint,
  @override bYN = 'N',
  @pphase bPhase = NULL OUTPUT,
  @desc varchar(255) = NULL OUTPUT,
  @PhaseGroupOUT tinyint = NULL OUTPUT,
  @contract bContract = NULL OUTPUT,
  @item bContractItem = NULL OUTPUT,
  @dept bDept = NULL OUTPUT,
  @projminpct real = NULL OUTPUT,
  @JCJPexists varchar(1) = NULL OUTPUT,
  @msg varchar(255) = NULL OUTPUT
)  AS 

   SET NOCOUNT ON
   
   declare @rcode int, @validphasechars int, @lockphases bYN, @active bYN, @inputmask varchar(30),
   		@rowcount int, @autoadditemyn bYN
   
   select @rcode = 0, @item=null, @dept=null, @JCJPexists='N', @msg = ''
   
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
   
    -- validate JC Company -  get valid portion of phase code
    select @validphasechars = ValidPhaseChars
    from JCCO with (nolock) where JCCo = @jcco
    if @@rowcount <> 1
        begin
        select @desc = 'Invalid Job Cost Company!', @rcode = 1
        goto bspexit
        end
   
    -- get Phase Group
    select @PhaseGroupOUT = PhaseGroup
    from HQCO with (nolock) where HQCo = @jcco
    if @@rowcount <> 1
        begin
        select @desc = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
        goto bspexit
        end
   
   --Issue 17738
   if @PhaseGroupOUT<>@phasegroup
   	begin
   	select @desc = 'Phase Group ' + isnull(convert(varchar(3), @PhaseGroupOUT),'') + ' for HQ Company ' 
   		+ isnull(convert(varchar(3),@jcco),'') + ' does not match Phase Group ' + isnull(convert(varchar(3), @phasegroup),''), @rcode = 1
       goto bspexit
   	end
   
   -- validate Job - get 'locked phases' flag
   -- when override flag is 'Y' use base table to bypass security otherwise use view - #23450
   -- if @override = 'N'
   -- 	begin
   -- 	select @contract = Contract, @lockphases = LockPhases, @autoadditemyn=AutoAddItemYN
   -- 	from JCJM with (nolock) where JCCo = @jcco and Job = @job
   -- 	if @@rowcount <> 1
   -- 	     begin
   -- 	     select @desc = 'Job ' + @job + ' not found!', @rcode = 1
   -- 	     goto bspexit
   -- 	     end
   -- 	end
   -- else
   -- 	begin
   	select @contract = Contract, @lockphases = LockPhases, @autoadditemyn=AutoAddItemYN
   	from bJCJM where JCCo = @jcco and Job = @job
   	if @@rowcount <> 1
   	     begin
   	     select @desc = 'Job ' + isnull(@job,'') + ' not found!', @rcode = 1
   	     goto bspexit
   	     end
   -- 	end
  
    -- first check Job Phases - exact match
    select @desc = Description, @pphase = Phase, @item = Item, @active = ActiveYN, @projminpct = ProjMinPct
    from bJCJP with (nolock)
    where JCCo = @jcco and Job = @job and Phase = @phase and PhaseGroup=@phasegroup /*133733*/
    if @@rowcount = 1
        begin
        select @JCJPexists = 'Y'
        if @active = 'Y' goto getjcdept   -- Phase is on file and active
		if @override = 'O' goto getjcdept -- phase is on file and override active
			select @desc = 'Phase ' + isnull(@phase,'') + ' for JC Co ' + convert(varchar,@jcco) + ', Job' + @job + ' is inactive!', @rcode = 1 --#136430
			goto bspexit
			end


    -- check 'locked phases' and override
    if @lockphases = 'Y' and @override <> 'Y'
        begin
        select @desc = 'Locked Phase ' + isnull(@phase,'') + ' is not on job' + isnull(@job,'') + '  - Job Phase Locked!', @rcode = 1   -- No new Phases allowed
        goto bspexit
        end
   
    -- check for a valid portion
    if isnull(@validphasechars,0) = 0 goto skipvalidportion
   
   
    -- format valid portion of Phase
    select @pphase = substring(@phase,1,@validphasechars) + '%'

 
   
    -- check valid portion of Phase in Job Phase table
    select Top 1 @desc = Description, @pphase = Phase, @item = Item, @projminpct = ProjMinPct 
    from bJCJP with (nolock)
    where JCCo = @jcco and Job = @job and Phase like @pphase  and PhaseGroup=@phasegroup /*133733*/
    Group By JCCo, Job, Phase, Item, Description, ProjMinPct
   
   -- -- -- -- -- separate out the contract item select so that we can get the min(Item)
   -- -- -- select @item = min(Item) from bJCJP  where JCCo = @jcco and Job = @job and Phase like @pphase
   
    skipvalidportion:
    -- full match in Phase Master will override description from partial match in Job Phase
    select @desc = isnull(isnull(Description,@desc),''), @pphase = isnull(Phase,@phase), @projminpct = ProjMinPct
    from bJCPM with (nolock)
    where PhaseGroup = @PhaseGroupOUT and Phase = @phase
   
    -- if we've got a Description we've found a match */
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
        where PhaseGroup = @PhaseGroupOUT and Phase like @pphase
        Group By PhaseGroup, Phase, Description, ProjMinPct
        if @@rowcount = 1
    	   begin
    	   select @rcode = 0
    	   goto getjcdept
    	   end
        end
    -- we are out of places to check
    select @desc = 'Phase ' + isnull(@phase,'') + ' not on file!', @rcode = 1
    goto bspexit
   
    getjcdept:  -- get JC Department from Contract Master or Item
        if @item is null
            begin
            -- get first Item on Contract
            select @item = min(Item) from bJCCI with (nolock) where JCCo = @jcco and Contract = @contract
            end
        if @item is null
            begin
            -- no Items on the Contract, use Department from Contract Master
            select @dept = Department from bJCCM with (nolock) where JCCo = @jcco and Contract = @contract
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
            if @@rowcount = 0 and isnull(@autoadditemyn,'') = 'N'
                begin
                select @desc = 'Contract Item ' + isnull(@item,'') + ' not set up!', @rcode = 1
                end
            end
   
   
   
   
   bspexit:
   	select @msg = @desc
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVPHASE] TO [public]
GO
