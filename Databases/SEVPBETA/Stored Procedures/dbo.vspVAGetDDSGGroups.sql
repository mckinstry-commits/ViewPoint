SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Dave C, vspVAGetDDSGGroups 
-- Create date: 5/27/09 
-- Description: returns DDSG users groups
-- =============================================  
CREATE PROCEDURE [dbo].[vspVAGetDDSGGroups]
 -- Add the parameters for the stored procedure here  
   
AS  
BEGIN  
	-- SET NOCOUNT ON added to prevent extra result sets from  
	-- interfering with SELECT statements.  
	SET NOCOUNT ON;  
	  
	SELECT [Name] AS [Group] FROM DDSG
	WHERE [Name] IS NOT NULL ORDER BY [Name]
END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetDDSGGroups] TO [public]
GO
