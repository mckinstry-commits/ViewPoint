SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDLoadColsListBox]
  /************************************************************************
  * CREATED: 	MV 03/02/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To load the Columns Listview on
  *									frmVAWDViewpointTables
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
       (@view varchar(25))   
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	select COLUMN_NAME  from INFORMATION_SCHEMA.COLUMNS 
		where TABLE_NAME = @view order by COLUMN_NAME
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDLoadColsListBox] TO [public]
GO
