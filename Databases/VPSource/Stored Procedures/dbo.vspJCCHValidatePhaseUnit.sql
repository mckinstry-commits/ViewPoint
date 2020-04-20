SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[vspJCCHValidatePhaseUnit]
  /***********************************************************
   * CREATED BY: DANF 06/5/2005
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Job Phase Master to warn the user that they have checked more than one
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
  
  	(@jcco bCompany = 0, @job bJob = null, @phase bPhase = null, @costtype bJCCType = null, @phaseunit bYN = null,
     @msg varchar(255) output)
  
	as
  	set nocount on
  
  	declare @rcode int, @count int
  	select @rcode = 0, @msg='', @count = 0
  
  	select @count=@@rowcount
  	from dbo.JCCH with (nolock)
  	where JCCo = @jcco and Job = @job and Phase = @phase and CostType <> @costtype and PhaseUnitFlag ='Y'

  	if isnull(@phaseunit,'N') = 'Y' select @count = @count +1
	
	if isnull(@count,0)>1
		begin
			select @msg = 'There is more than one Phase Cost Type with Phase Unit Flag checked.',@rcode =1
		end

  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCHValidatePhaseUnit] TO [public]
GO
