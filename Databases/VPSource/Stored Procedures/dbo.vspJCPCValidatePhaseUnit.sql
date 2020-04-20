SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspJCPCValidatePhaseUnit]
  /***********************************************************
   * CREATED BY: DANF 05/18/2005
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Phase Master to warn the user that they have checked more than one
   * Phase Unit flag 
   *
   * INPUT PARAMETERS
   *   Phase Group		
   *   Phase
   *   Cost Type
   *
   * OUTPUT PARAMETERS
   *   @msg      Warning
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@phasegroup bGroup = 0, @phase bPhase = null, @costtype bJCCType = null, @phaseunit bYN = null,
     @msg varchar(255) output)
  
	as
  	set nocount on
  
  	declare @rcode int, @count int
  	select @rcode = 0, @msg='', @count = 0
  
  	select @count=@@rowcount
  	from dbo.JCPC with (nolock)
  	where PhaseGroup = @phasegroup and Phase = @phase and CostType <> @costtype and PhaseUnitFlag ='Y'

  	if isnull(@phaseunit,'N') = 'Y' select @count = @count +1
	
	if isnull(@count,0)>1
		begin
			select @msg = 'There is more than one Phase Cost Type with Phase Unit Flag checked.',@rcode =1
		end

  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPCValidatePhaseUnit] TO [public]
GO
