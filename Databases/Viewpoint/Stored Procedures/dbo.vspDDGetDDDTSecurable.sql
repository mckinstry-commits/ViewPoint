SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDGetDDDTSecurable]
  /***************************************
  * Created: AL 6/16/06
  * Modified: 
  *
  * Retrieves all rows from the DDDTSecurable view
  * that have been secured.
  *
  * 
  *
  *
  **************************************/
  	(@msg varchar(60) = null output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
    
  select *
  from dbo.DDDTSecurable where Secure = 'Y'
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDGetDDDTSecurable] TO [public]
GO
