SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDLoadIndxListBox]
  /************************************************************************
  * CREATED: 	MV 03/02/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To load the Column Index Listview on
  *									frmVAWDViewpointTables
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
       (@view varchar(4))   
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	select colname from brvDDIndexes where objectname = 'b' + @view order by colname
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDLoadIndxListBox] TO [public]
GO
