SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAP1099TypeDesc]
  /***************************************************
  * CREATED BY    : MV 
  * LAST MODIFIED : 
  * Usage:
  *   Returns description to AP1099Type form
  *
  * Input:
  *	@1099Type      
  *
  * Output:
  *   @msg          description 
  *
  * Returns:
  *	0             success
  * 1             error
  *************************************************/
  	(@1099type varchar(10),@msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
   
  select @msg = Description  from bAPTT with (nolock)
	 where V1099Type=@1099type
 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAP1099TypeDesc] TO [public]
GO
