SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspVAGetServicePack]
   /*************************************************************************************
   *    Created:	TMS 09/04/09 - Return installed version and service pack for Help, About box
   *
   *    Purpose: Called from Viewpoint Client Help About form to get the service pack  
   *	number that has been installed.
   *                
   **************************************************************************************/
      
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT isnull([Version],'') + ' ' + isnull([ServicePack],'') FROM [dbo].DDVS (nolock)


	
END



GO
GRANT EXECUTE ON  [dbo].[vspVAGetServicePack] TO [public]
GO
