SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDLoadMOCombo]
  /************************************************************************
  * CREATED: 	MV 03/02/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To fill the Module combo box on
  *									frmVAWDViewpointTables
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
          
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	Select Mod from DDMO with (nolock) where Mod <>'DD'
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDLoadMOCombo] TO [public]
GO
