SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJCDeptDesc]
  /***********************************************************
   * CREATED BY: DANF 05/19/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Department Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Department  		Department
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@jcco bCompany = 0, @dept bDept = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@dept,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.JCDM with (nolock)
		  where JCCo = @jcco and Department = @dept
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCDeptDesc] TO [public]
GO
