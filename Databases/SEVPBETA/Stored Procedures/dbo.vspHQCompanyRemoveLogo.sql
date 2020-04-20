SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspHQCompanyRemoveLogo]        
-- =============================================        
-- Created: 12/06/11        
      
-- =============================================         
 (@companyID smallint)        
        
as        
BEGIN       
Delete from vCompanyImages    
where Id=@companyID    
END 
GO
GRANT EXECUTE ON  [dbo].[vspHQCompanyRemoveLogo] TO [public]
GO
