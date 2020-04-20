SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMCostCodeDesc]
  /***********************************************************
   * CREATED BY: DANF 01/03/2007
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in EM Cost Code Master to return the a description to the key field.
   *
   * INPUT PARAMETERS
   *   EMCo   			EM Co 
   *   CostCode 	    CostCode
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of CostCode if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@emgroup bGroup = 0, @costcode varchar(10) = null, @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''
  
 	if @emgroup is not null and  isnull(@costcode,'') <> ''
		begin
		  select @msg = Description 
		  from dbo.EMCC with (nolock)
		  where EMGroup = @emgroup and CostCode = @costcode
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCostCodeDesc] TO [public]
GO
