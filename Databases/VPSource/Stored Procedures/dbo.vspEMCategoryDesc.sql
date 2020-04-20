SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMCategoryDesc]
  /***********************************************************
   * CREATED BY: DANF 01/03/2007
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in EM Category Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   EMCo   			EM Co 
   *   Category Code 	Category
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Category Code if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@emco bCompany = 0, @category varchar(10) = null, @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @emco is not null and  isnull(@category,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.EMCM with (nolock)
		  where EMCo = @emco and Category = @category
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCategoryDesc] TO [public]
GO
