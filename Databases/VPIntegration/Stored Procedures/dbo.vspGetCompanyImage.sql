SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspGetCompanyImage]
-- =============================================
-- Created: 2011-12-21 Chris Crewdson
-- Updated: 
-- =============================================
 (@companyID smallint)
        
as        
SET NOCOUNT OFF
    
BEGIN
  SELECT CompanyLogo
  FROM CompanyImages
  where Id=@companyID
END 
GO
GRANT EXECUTE ON  [dbo].[vspGetCompanyImage] TO [public]
GO
