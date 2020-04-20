SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspPCPhaseValSelectBidders]
/***********************************************************
* CREATED BY:		JG 12/09/2010
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

	--Removes dashes and spaces for the word Multiple
	IF (REPLACE(REPLACE(@phase, '-', ''), ' ', '') = 'Multiple')
	BEGIN
		SELECT @msg = 'Pulled from Bid Package'
	END
	ELSE
	BEGIN 
		select @msg = isnull(Description,'')
		from bJCPM with (nolock)
		where PhaseGroup = @phasegroup and Phase = @phase
    END
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPhaseValSelectBidders] TO [public]
GO
