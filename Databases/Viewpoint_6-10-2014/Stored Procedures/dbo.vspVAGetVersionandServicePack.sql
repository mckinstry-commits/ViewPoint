SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspVAGetVersionandServicePack]
   /*************************************************************************************
   *    Created:	TMS 09/04/09 - Return installed version and service pack for Help, About box
   *                George Clingerman 10/29/2009 - Enhanced selection of Service Pack to account for NULLs
   *    Modified:   FDT - Added TaxUpdate column and broke ServicePack out from Version
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

	--SELECT isnull([Version],'') + ' ' + CASE isnull([ServicePack], '') WHEN '' THEN '' ELSE 'Service Pack ' + [ServicePack] END FROM [dbo].DDVS (nolock)
	SELECT [Version], ServicePack, TaxUpdate FROM [dbo].DDVS (nolock)
	
END




GO
GRANT EXECUTE ON  [dbo].[vspVAGetVersionandServicePack] TO [public]
GO
