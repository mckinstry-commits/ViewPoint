SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfServiceDivisions]
/****************************************
 * Created By:	GPT 08/05/2011
 * Modified By:	JG	08/12/2011 - Added DISTINCT to avoid duplicate entries.
 *
 *	Called by ServiceDivisionFilter to get list of divisions 
 *  by company and service center
 *
 * Returns:
 * dataset of Service Divisions
 *
 *
 **************************************/
(@Company bCompany, @ServiceCenter varchar(10))
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT	'All' AS Division
		
	UNION ALL
	
	SELECT DISTINCT Division
	FROM dbo.SMDivision 
	WHERE SMCo = @Company AND (ServiceCenter = @ServiceCenter OR @ServiceCenter is Null)
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfServiceDivisions] TO [public]
GO
