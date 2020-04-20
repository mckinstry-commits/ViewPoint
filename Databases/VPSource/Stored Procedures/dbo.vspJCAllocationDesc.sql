SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCAllocationDesc]
  /***********************************************************
   * CREATED BY: DANF 11/16/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Allocation Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Allocation Code 	Allocation Code
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Allocation if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@jcco bCompany = 0, @alloccode tinyint = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@alloccode,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.JCAC with (nolock)
		  where JCCo = @jcco and AllocCode = @alloccode
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAllocationDesc] TO [public]
GO
