SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelPayTypeList]
  /************************************************************************
  * CREATED: 	MV 06/02/05   
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To return a list of PayTypes and descriptions
  *									to fill the PayType ListBox in APHoldRel
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
      (@co int)
  
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	Select PayType, Description from APPT Where APCo=@co
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelPayTypeList] TO [public]
GO
