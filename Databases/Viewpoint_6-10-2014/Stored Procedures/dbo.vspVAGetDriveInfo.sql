SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVAGetDriveInfo]  
 /**************************************************    
  * Created By: Narendra 10/18/2012     
  *    
  * USAGE:    
  * Retrieves drive info of the server.    
  * Used by Company Copy Wizard to display drive to save database backup on.   
  * Return code:
  *	0 = success, 1 = error
  *    
  *************************************************/    
AS    
SET nocount ON

DECLARE @rcode INT
SET @rcode = 0

BEGIN TRY 
	Exec master.dbo.xp_fixeddrives  
END TRY
BEGIN CATCH
	SET @rcode = 1
END CATCH

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAGetDriveInfo] TO [public]
GO
