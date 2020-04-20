SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMComponentTypeDesc]
  /***********************************************************
   * CREATED BY: DANF 01/03/2007
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in EM ComponentType Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   EMCo   			EM Co 
   *   Category Code 	ComponentType
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of ComponentType if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@emgroup bGroup = 0, @componenttype varchar(10) = null, @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @emgroup is not null and  isnull(@componenttype,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.EMTY with (nolock)
		  where EMGroup = @emgroup and ComponentTypeCode = @componenttype
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMComponentTypeDesc] TO [public]
GO
