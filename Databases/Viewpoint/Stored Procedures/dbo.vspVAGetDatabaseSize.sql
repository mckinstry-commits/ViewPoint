SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVAGetDatabaseSize]  
 /**************************************************    
  * Created By: Narendra 10/23/2012     
  *    
  * USAGE:    
  * Retrieves size of the database.    
  * Used by Company Copy Wizard to validate size of the database against available free space.   
  * Return code:
  *	0 = success, 1 = error
  *    
  *************************************************/    
AS    
SET nocount ON

DECLARE @rcode INT
SET @rcode = 0

BEGIN TRY 
	EXEC sp_spaceused
END TRY
BEGIN CATCH
	SET @rcode = 1
END CATCH

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAGetDatabaseSize] TO [public]
GO
