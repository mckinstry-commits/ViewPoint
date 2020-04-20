SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCVPHASE    Script Date: 8/28/99 9:35:07 AM ******/
CREATE   procedure [dbo].[vspPCPhaseVal]
/***********************************************************
* CREATED BY:		CHS 03/16/2010
* MODIFIED By:
*
*
* USAGE:
* Simple Phase validation procedure.  Returns phase description only.
*
* INPUT PARAMETERS
*    @jcco         Job Cost Company
*    @phase        Phase to validate
*    @phasegroup   group to validate against PhaseGroup in HQCO
*
* OUTPUT PARAMETERS
*    @msg          Phase description, or error message.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/
(@phasegroup bGroup, @phase bPhase = null, @msg varchar(255) = null output)
    as
    set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @msg = ''
    	
    if @phasegroup is null
    	begin
    	select @msg = 'Missing Phase Group!', @rcode = 1
    	goto bspexit
    	end
   
      if @phase is null
    	begin
    	select @msg = 'Missing Phase!', @rcode = 1
    	goto bspexit
    	end

    select @msg = isnull(Description,'')
    from bJCPM with (nolock)
    where PhaseGroup = @phasegroup and Phase = @phase
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPhaseVal] TO [public]
GO
