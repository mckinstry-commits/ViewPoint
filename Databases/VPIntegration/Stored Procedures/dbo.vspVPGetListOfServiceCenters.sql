SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfServiceCenters]
/****************************************
 * Created By:	GPT 07/28/2011
 * Modified By:	
 *
 *	Called by ServiceCenterFilter to get list of centers by company
 *
 * Returns:
 * dataset of all ServiceCenters
 *
 *
 **************************************/
(@Company bCompany)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT	'All' AS ServiceCenter
		
	UNION ALL
	
	SELECT ServiceCenter
	FROM dbo.SMServiceCenter 
	WHERE SMCo = @Company
END




GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfServiceCenters] TO [public]
GO
