SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCProjectManagerDesc]
  /***********************************************************
   * CREATED BY: DANF 08/11/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JCProject Manager to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   JCCo   			
   *   Project Mananger
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Name of the project manager.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@jcco bCompany = 0, @projectmgr int = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@projectmgr,'') <> ''
		begin
		  select @msg = Name 
		  from dbo.JCMP with (nolock)
		  where JCCo = @jcco and ProjectMgr = @projectmgr
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProjectManagerDesc] TO [public]
GO
