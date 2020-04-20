SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAValidateTemplateNumber]
/**************************************************      
* Created: Dave C 6/1/2009    
* Modified:       
*       
*      
* Validation procedure checks if Template number exists, and if so,
* returns the template title.
*      
* Inputs: @TemplateID  
*      
* Output: @errmsg
*      
*      
*      
****************************************************/      
(@TemplateID smallint, @errmsg varchar(255) = null output)  
  
AS  

Declare @rcode int  
select @rcode = 0  

IF NOT EXISTS(
	SELECT
		Top 1 1
	FROM
		DDTFShared
	WHERE FolderTemplate = @TemplateID
		)
		BEGIN
			SELECT @errmsg = 'Invalid Template number', @rcode = 1
			GOTO vspexit
		END
	
SELECT
	@errmsg =
		(
			SELECT Title from DDTFShared where FolderTemplate = @TemplateID
		)

vspexit:
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAValidateTemplateNumber] TO [public]
GO
