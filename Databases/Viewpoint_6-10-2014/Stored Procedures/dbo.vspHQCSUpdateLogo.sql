SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspHQCSUpdateLogo]        
-- =============================================        
-- Created: 12/06/11        
-- Updated: 12/20/11    
-- Removed MIME column as it is not required
-- =============================================         
 (@companyID smallint , @companyLogo image = null)        
        
as        
SET NOCOUNT OFF      
    
BEGIN       
  UPDATE dbo.vCompanyImages    
  SET CompanyLogo=@companyLogo
  where Id=@companyID    
     
 IF @@ROWCOUNT =0    
 BEGIN       
 INSERT INTO vCompanyImages(Id,CompanyLogo)    
 VALUES (@companyID,@companyLogo)     
 END     
END 
GO
GRANT EXECUTE ON  [dbo].[vspHQCSUpdateLogo] TO [public]
GO
