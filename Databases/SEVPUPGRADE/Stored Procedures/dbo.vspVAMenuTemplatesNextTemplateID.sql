SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  /*Created - Dave C 5/22/2009,   
  *
  *	Gets next custom FolderTemplate id in DDTFShared
  *
  * Inputs:
  *		@nextreportid int
  *		@msg varchar(255)
  *
  */
CREATE PROCEDURE [dbo].[vspVAMenuTemplatesNextTemplateID]    
(@nexttemplateid int = 0 output, @msg varchar(255) output)    

AS  
    
SET NOCOUNT ON

DECLARE @rcode int    
SELECT @rcode=0    
   
-- Standard Template IDs (FolderTemplate #) should never be above 9999  
SELECT
	@nexttemplateid = Max(FolderTemplate)

FROM dbo.DDTFShared  
   
IF @nexttemplateid < 10000 /*If there are only Standard templates*/  
	BEGIN    
		SELECT @nexttemplateid = 10000  
	END
ELSE  
	BEGIN  
		-- Increment all future custom FolderTemplate #s  
		SELECT @nexttemplateid = Max(FolderTemplate)+1 From  dbo.DDTFShared   
	END
   
IF @nexttemplateid > 32767  
	BEGIN
		SELECT @msg = 'Next Template ID has exceded small int precision.', @rcode = 1	
	END

IF @rcode <> 0     
	BEGIN
		SELECT @msg = @msg + char(13) + char(10) + ' [vspVAMenuTemplatesNextTemplateID]'    
	END

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAMenuTemplatesNextTemplateID] TO [public]
GO
