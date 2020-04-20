SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPMValForJCTN    Script Date: 8/28/99 9:33:00 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCPMValForJCTN    Script Date: 2/12/97 3:25:07 PM ******/
   CREATE   proc [dbo].[bspJCPMValForJCTN]
   	(@jcco bCompany, @PhaseGroup tinyint, @phase bPhase = null, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: SE   10/11/96
    * MODIFIED By : SE 10/11/96
    *				TV - 23061 added isnulls
    * USAGE:
    * validates JC Phase from Phase Master.
    * an error is returned if any of the following occurs
    * no phase passed, no phase found in JCPM.
    *
    * INPUT PARAMETERS
    *   PhaseGroup  JC Phase group for this company
    *   Phase       Insurance template to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Template description
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   
   	declare @rcode int, @validphasechars int
       declare @inputmask varchar(30), @pphase bPhase
   	select @rcode = 0
   
   if @phase is null
   	begin
   	select @msg = 'Missing Phase', @rcode = 1
   	goto bspexit
   	end
   
   if @jcco is null
   	begin
   	select @msg = 'Missing Company', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from JCPM
   	where PhaseGroup = @PhaseGroup and Phase = @phase
   if @@rowcount=0
      begin
        select @validphasechars = ValidPhaseChars from bJCCO where JCCo=@jcco
        if @@rowcount=0
   	begin
   	  select @msg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
   	  goto bspexit
   	end
        if @validphasechars=0
   	begin
    	 select @msg = 'Missing Phase', @rcode = 1
   	 goto bspexit
   	end
   
        /* get the mask for bPhase */
        select @inputmask=InputMask from DDDTShared where Datatype = 'bPhase'
   
        /* format validportion of phase */
        select @pphase=substring(@phase,1,@validphasechars) + '%'
   
        /*exec @rcode = bspHQFormatMultiPart @pphase,@inputmask,@pphase output*/
   
        select TOP 1 @msg = Description
   	 from JCPM
   	 where PhaseGroup = @PhaseGroup and Phase like @pphase
        Group By PhaseGroup, Phase, Description
        if @@rowcount = 0
   	  begin
   	   select @msg = 'Phase not setup in Phase Master.', @rcode = 1
   	   goto bspexit
   	  end
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPMValForJCTN] TO [public]
GO
