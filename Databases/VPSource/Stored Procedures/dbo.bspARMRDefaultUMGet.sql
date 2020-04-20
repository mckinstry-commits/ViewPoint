SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARMRDefaultUMGet    Script Date: 8/28/99 9:32:35 AM ******/
   CREATE  proc [dbo].[bspARMRDefaultUMGet]
   /*************************************
   * CREATED BY: JM   12/9/97
   * MODIFIED By:
   *
   * Returns default UM from JCCH for AR Misc Receipts form
   *
   * Pass:
   *	JCCo
   *	Job
   *	Phase
   *	CostType
   *
   * Derives:
   *	PhaseGroup from HQCO where HQCo = passed JCCo
   *
   * Success returns:
   *	0 and default UM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@jcco bCompany = null, @job bJob = null, @phase bPhase = null,
   	@costtype bJCCType = null, @defum bUM = null output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   declare @phasegroup bGroup
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
   /* derive phase group from HQCO where HQCo = @jcco */
   select @phasegroup = PhaseGroup
   from HQCO
   where HQCo = @jcco
   if @phasegroup is null
   	begin
   	select @defum = '' /* return success, ie rcode = 0 */
   	goto bspexit
   	end
   /* select default um from JCCH */
   select @defum = UM
   from JCCH
   where JCCo = @jcco and
   	Job = @job and
   	PhaseGroup = @phasegroup and
   	Phase = @phase and
   	CostType = @costtype
   if @@rowcount = 0
   	begin
   	select @defum = '' /* return success, ie rcode = 0 */
   	goto bspexit
   	end
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARMRDefaultUMGet]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARMRDefaultUMGet] TO [public]
GO
