SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCRollUpDesc]
  /***********************************************************
   * CREATED BY: DANF 08/03/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Roll Up Code Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Roll Up Code 	Department
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Roll Up Code if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@jcco bCompany = 0, @rollupcode varchar(5) = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@rollupcode,'') <> ''
		begin
		  select @msg = RollupDesc 
		  from dbo.JCRU with (nolock)
		  where JCCo = @jcco and RollupCode = @rollupcode
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCRollUpDesc] TO [public]
GO
