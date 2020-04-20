SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARMRDefaultGLAcctGet    Script Date: 8/28/99 9:34:13 AM ******/
CREATE  proc [dbo].[bspARMRDefaultGLAcctGet]
/*************************************
* CREATED BY:  JM 12/9/97
* MODIFIED By: bc 05/29/01 - derive the Department from JCCI instead of JCCM
*              allenn  - issue 14175. new phase override gl accounts from JC Department Master.
*				GG 05/15/02 - #17137 - pull dept from first contract item
*				DANF 10/30/03 - 22786 Added Phase GL Account valid part over ride.
* 				DANF 09/08/05 - 27545 GL Account is not defaulting to correct department when Job Phase does not exist.
*				GG 10/16/07 - #125791 - fix for DDDTShared
*
* Returns default GLAcct for AR Misc Receipts form from JCDC
*	Selects OpenWIPAcct if JCJM.JobStatus = Soft-Closed or Open
*	Selects ClosedExpAcct if JCJM.JobStatus = Hard-Closed
*
* Pass:
*	JCCo
*	Job
*	CostType
*
* Derives:
*	PhaseGroup from HQCO where HCCo = passed JCCo
*	Department and JobStatus from JCCM
*		where JCCM.JCCo = passed JCCo and
*		JCCM.Contract = JCJM.Contract (by JCCo and Job)
*
* Success returns:
*	0 and GLAcct
*
* Error returns:
*	1 and error message
**************************************/
    	(@jcco bCompany = null, @job bJob = null, @phase bPhase = null,
    	@costtype bJCCType = null, @defglacct bGLAcct output, @msg varchar(60) output)
    as
    set nocount on
    declare @rcode int
    declare @phasegroup bGroup
    --declare @contract bContract
    --declare @contractitem bContractItem
    declare @department bDept
    declare @jobstatus tinyint
    declare @openwipacct bGLAcct
    declare @closedexpacct bGLAcct
    declare @InputMask varchar(30), @InputType tinyint, @validphase bPhase, @pphase bPhase, @validphasechars int
   
    select @rcode = 0
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
   
   -- get Phase Format 
   select @InputMask = InputMask, @InputType= InputType
   from dbo.DDDTShared with (nolock) where Datatype ='bPhase'
    
   
    /* derive Phase Group from HQCO */
    select @phasegroup = PhaseGroup
    from dbo.HQCO with (nolock)
    where HQCo = @jcco
    if @phasegroup is null
    	begin
    	select @defglacct = '' /* return success, ie rcode = 0 */
    	goto bspexit
    	end
   
    /* derive Contract and Job Status from JCJM */
    select @jobstatus = JobStatus
    from dbo.bJCJM with (nolock)
    where JCCo = @jcco and Job = @job
   
    /* get the contract item from JCJP because we're going to derive the department from JCCI */
    --select @contractitem = Item
    --from bJCJP
    --where JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and Contract = @contract
   
    /* derive Department from JCCI */
    --select @department = Department
    --from bJCCI
    --where JCCo = @jcco and Contract = @contract and Item = @contractitem
   
    -- get JC Department
    exec @rcode =  dbo.bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'Y', @dept = @department output,
         @msg = @msg output
 
   -- Ref 17137: if JC Department is null, get it from the first Contract Item
   if @department is null
       begin
       select @department = i.Department
       from dbo.bJCCI i  with (nolock)
   	join dbo.bJCJM j  with (nolock) on j.JCCo = i.JCCo and j.Contract = i.Contract
   	where j.JCCo = @jcco and j.Job = @job
           and i.Item = (select min(i.Item) from bJCCI i
   			          join dbo.bJCJM j  with (nolock) on j.JCCo = i.JCCo and j.Contract = i.Contract
                    	  where j.JCCo = @jcco and j.Job = @job)
       end
    /* finally derive default GLAcct from JCDC by JCCo, Department,
    * PhaseGroup, and CostType. If JobStatus = Soft-Closed or Open
    * choose OpenWIPAcct else choose ClosedExpAcct */
   --Issue 14175
   select @openwipacct = OpenWIPAcct, @closedexpacct = ClosedExpAcct
   from dbo.bJCDO with (nolock)
   where JCCo = @jcco and Department = @department and PhaseGroup = @phasegroup and Phase = @phase
    	if @@rowcount = 0
    	begin
    	-- check Phase Master using valid portion
    	-- validate JC Company -  get valid portion of phase code
    	select @validphasechars = ValidPhaseChars
    	from dbo.bJCCO with (nolock) where JCCo = @jcco
    	if @@rowcount <> 0
    	begin
    	if @validphasechars > 0
    	begin
    	--select @pphase = substring(@phase,1,@validphasechars) + '%'
   	select @validphase  = substring(@phase,1,@validphasechars)
       exec @rcode = dbo.bspHQFormatMultiPart @validphase, @InputMask, @pphase output
    	select @openwipacct = case @jobstatus when 3 then d.ClosedExpAcct else d.OpenWIPAcct end
    	from dbo.bJCDO d with (nolock) 
    	join dbo.bHQCO c with (nolock) ON d.JCCo = c.HQCo
    	where d.JCCo = @jcco and d.Department = @department and d.Phase = @pphase and
    	d.PhaseGroup = c.PhaseGroup
    	end -- end valid part
    	end-- end select of jc company
    	end -- end of full phase not found
  
   if @openwipacct is null
   	begin
   	select @openwipacct = OpenWIPAcct, @closedexpacct = ClosedExpAcct
   	from dbo.bJCDC with (nolock)
   	where JCCo = @jcco and Department = @department and PhaseGroup = @phasegroup and CostType = @costtype
   	end

    if @jobstatus in (1,2) /* Open or Soft-Closed */
    	select @defglacct = @openwipacct
    else /* @jobstatus = 3, Hard-Closed */
    	select @defglacct = @closedexpacct
  
 
 
    bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARMRDefaultGLAcctGet]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARMRDefaultGLAcctGet] TO [public]
GO
