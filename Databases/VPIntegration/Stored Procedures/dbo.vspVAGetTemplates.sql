SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Dave C, [vspVAGetTemplates] 
-- Create date: 5/27/09 
-- Description: returns DDTFShared templates
-- =============================================  
CREATE PROCEDURE [dbo].[vspVAGetTemplates]
   
AS  
BEGIN  
	-- SET NOCOUNT ON added to prevent extra result sets from  
	-- interfering with SELECT statements.  
	SET NOCOUNT ON;  
	  
	SELECT Title FROM DDTFShared
	WHERE Active <> 'N' ORDER BY Title
END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetTemplates] TO [public]
GO
