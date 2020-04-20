SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRJCCostTypeVal    Script Date: 8/28/99 9:36:48 AM ******/
   
    CREATE   procedure [dbo].[bspPRJCCostTypeVal]
     /************************************************************
      * CREATED BY: EN 2/08/01
      *			SR 07/09/02 Issue 17738 pass @phasegroup to bspJCVCOSTTYPE
      *            DANF 09/06/02 - 17738 Change lookup of phase group to HQCO.
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
      *
      * OUTPUT PARAMETERS
      *   @errmsg       error message
      *
      * RETURN VALUE
      *   0   success
      *   1   fail
      ************************************************************/
     	@co bCompany, @earncode bEDLCode, @jcco bCompany, @job bJob, @phase bPhase,
       @errmsg varchar(255) output
     as
     set nocount on
   
     declare @rcode int, @jccosttype bJCCType, @vct varchar(5), @msg varchar(60), @phasegroup bGroup
   
     select @rcode = 0
   
     /* skip if validation inputs missing */
     if @co is null or @earncode is null or @jcco is null or @job is null or @phase is null
     	goto bspexit
   
     select @jccosttype = JCCostType from bPREC where PRCo = @co and EarnCode = @earncode
     select @vct = convert(varchar(5),@jccosttype)
   
   select @phasegroup=PhaseGroup from bHQCO where HQCo=@jcco
   
     exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @vct, 'N', @msg = @errmsg output
     if @rcode <> 0
        begin
        goto bspexit
        end
   
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRJCCostTypeVal] TO [public]
GO
