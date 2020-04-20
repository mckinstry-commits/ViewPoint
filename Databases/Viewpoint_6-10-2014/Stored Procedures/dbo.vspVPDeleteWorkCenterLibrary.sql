SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVPDeleteWorkCenterLibrary]
  /************************************************************************
  * CREATED: 	HH 03/21/2013 		TFS 43740
  * MODIFIED:   
  *
  * Purpose of Stored Procedure:	Delete a library from VPWorkCenterUserLibrary
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
(@Owner bVPUserName = null, @LibraryName varchar(50))

AS
SET NOCOUNT ON

DECLARE @rcode int
SET @rcode = 0

BEGIN TRY

	IF @Owner IS NULL
	BEGIN
		SET @Owner = SUSER_SNAME()
	END
	
	DELETE 
	FROM VPWorkCenterUserLibrary 
	WHERE LibraryName = @LibraryName AND [Owner] = @Owner
		
END TRY
BEGIN CATCH
    
     SET @rcode = 1
     
END CATCH

bspexit:
RETURN @rcode








GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteWorkCenterLibrary] TO [public]
GO
