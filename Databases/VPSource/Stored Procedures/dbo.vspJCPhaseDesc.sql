SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCPhaseDesc]
  /***********************************************************
   * CREATED BY: DANF 04/25/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Phase Master to return a description to the key field.
   *
   * INPUT PARAMETERS
   *   Phase Group		
   *   Phase
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Template if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@group bGroup = 0, @phase bPhase = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @group is not null and  isnull(@phase,'')<>''
		begin
		  select @msg = Description 
		  from dbo.JCPM with (nolock)
		  where PhaseGroup = @group and Phase = @phase
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPhaseDesc] TO [public]
GO
