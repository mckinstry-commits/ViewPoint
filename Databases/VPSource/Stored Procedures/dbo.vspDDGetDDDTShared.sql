SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDGetDDDTShared]
  /***************************************
  * Created: JRK 10/10/06
  * Modified: 
  *
  * Retrieves all rows from the DDDTShared view (vDDDT + vDDDTc).
  *
  * Used on forms VAHQUDAdd
  *
  *
  **************************************/
  	(@msg varchar(60) = null output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
    
  select *
  from dbo.DDDTShared
  
vspexit:
  	return @rcode
  
 

grant exec on vspDDGetDDDTShared to public

GO
GRANT EXECUTE ON  [dbo].[vspDDGetDDDTShared] TO [public]
GO
