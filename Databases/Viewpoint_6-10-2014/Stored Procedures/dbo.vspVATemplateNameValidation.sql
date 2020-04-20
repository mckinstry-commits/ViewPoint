SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================      
-- Author:  Dave C, vspVATemplateNameValidation  
-- Create date: 6/10/09     
-- Description: Query returns the users in DDSG groups  
-- =============================================  
  
CREATE PROCEDURE [dbo].[vspVATemplateNameValidation]  
  
(@templatename bDesc, @errmsg varchar(60) OUTPUT)  
  
AS  
  
SET NOCOUNT ON;

declare @rcode int  
select @rcode = 0  
  
IF @templatename IS NULL  
 BEGIN  
  SELECT @errmsg = 'Template name does not exist.', @rcode = 1
  goto vspexit
 END  
  
IF EXISTS(SELECT Title from DDTFShared  
    WHERE Title = @templatename)  
 BEGIN  
    SELECT @errmsg = 'Duplicate template name.', @rcode = 1  
 END
 
 vspexit:
 return @rcode 
GO
GRANT EXECUTE ON  [dbo].[vspVATemplateNameValidation] TO [public]
GO
