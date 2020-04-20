SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVACompanyCopyLoad]
  /************************************************************************
  * CREATED: 	MV 05/30/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	return server and database to
  *									frmCompanyCopyforServer
  *    
  *
  *************************************************************************/
       (@servername varchar(55) output, @dbname varchar(55) output)   
  as
  set nocount on
  
  select @servername=@@servername, @dbname=DB_Name()
  
  return 
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyLoad] TO [public]
GO
