SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDLoadViewsCombo]
  /************************************************************************
  * CREATED: 	MV 03/02/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To fill the Views combo box on
  *									frmVAWDViewpointTables
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
       (@module varchar(2))   
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	Select TABLE_NAME from INFORMATION_SCHEMA.VIEWS 
		where TABLE_NAME like @module + '%' order by TABLE_NAME
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDLoadViewsCombo] TO [public]
GO
