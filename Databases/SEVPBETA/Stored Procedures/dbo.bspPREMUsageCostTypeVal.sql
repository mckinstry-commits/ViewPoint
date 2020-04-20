SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREMUsageCostTypeVal    Script Date: 8/28/99 9:36:48 AM ******/
   
    CREATE     procedure [dbo].[bspPREMUsageCostTypeVal]
     /************************************************************
      * CREATED BY: kb 5/21/01
      * MODIFIED BY: EN 3/08/02 - issue 14181 if equip phase override was selected, validate using that phase
      *				SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
      *                DANF 09/06/02 - 17738 Changed lookup for phase group to HQCO
	  *				EN 8/15/07 - return @costtypeout for 6.0 recode
      *
      *
      * USAGE:
      * Called by PRTimeCards to validate Job/Phase/CostType associated with Earnings Code posted.
      *
      * INPUT PARAMETERS
      *   @co           PR Co#
      *   @earncode     Earnings Code
      *   @jcco         JC Co#
      *   @job          Job Code
      *   @phase        Phase Code
      *   @equipphase	 Equipment Phase code override
      *
      * OUTPUT PARAMETERS
      *   @errmsg       error message
      *
      * RETURN VALUE
      *   0   success
      *   1   fail
      ************************************************************/
		@co bCompany, @emctype varchar(10) = null, @jcco bCompany, @job bJob, @phase bPhase,
		@equipphase bPhase = null, @costtypeout bJCCType = null output, @errmsg varchar(255) output
     as
	set nocount on

	declare @rcode int, @vct varchar(10), @msg varchar(60), @usgphase bPhase, @phasegroup tinyint

	select @rcode = 0
   
	/* skip if validation inputs missing */
	if @co is null or @emctype is null or @jcco is null or @job is null or (@phase is null and @equipphase is null)
	goto bspexit
   
	select @vct = convert(varchar(10),@emctype)

	select @usgphase = @phase

	if @equipphase is not null select @usgphase = @equipphase

	select @phasegroup=PhaseGroup from bHQCO where HQCo=@jcco

	if @phasegroup is null 
		select @phasegroup=PhaseGroup from JCPM where PhaseGroup=(select PhaseGroup from HQCO where HQCo=@jcco)

	--exec @rcode = bspJCVCOSTTYPE @jcco, @job,@phasegroup,@usgphase, @vct, 'N', @msg = @errmsg output
	exec @rcode = bspJCVCOSTTYPE @jcco, @job,@phasegroup,@usgphase, @vct, 'N', @costtypeout = @costtypeout output, @msg = @errmsg output
	
	if @rcode <> 0
	begin
		goto bspexit
	end

   
    bspexit:

  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREMUsageCostTypeVal] TO [public]
GO
