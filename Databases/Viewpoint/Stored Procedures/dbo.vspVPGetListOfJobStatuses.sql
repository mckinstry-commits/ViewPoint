SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetListOfJobStatuses]
/****************************************
 * Created By:	HH 03/12/2011
 * Modified By:	
 *
 *	Called by Tree view in my viewpoint to get list of all job statuses
 *
 * Returns:
 * dataset of all job statuses
 *
 *
 **************************************/
AS
BEGIN
	SET NOCOUNT ON;

	SELECT '-1' AS DatabaseValue, 'All' AS DisplayValue
	
	UNION ALL
	
	SELECT DatabaseValue, DisplayValue
	FROM dbo.DDCI 
	WHERE ComboType = 'JCJMJobStatus'
END




GO
GRANT EXECUTE ON  [dbo].[vspVPGetListOfJobStatuses] TO [public]
GO
