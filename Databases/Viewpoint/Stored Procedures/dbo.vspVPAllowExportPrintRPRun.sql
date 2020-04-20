SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CJG
* Create date:  08/02/2010
* Description:	Get the DDVS value for AllowExportPrintRPRun
*
*	Inputs:
*
*	Outputs:
*	@ShowMyViewpoint		bYN value for AllowExportPrintRPRun
*	
*	Returns:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPAllowExportPrintRPRun] 
	-- Add the parameters for the stored procedure here
	@AllowExportPrintRPRun bYN = 'Y' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT TOP 1 @AllowExportPrintRPRun = ISNULL(AllowExportPrintRPRun, 'N') FROM vDDVS
END

GO
GRANT EXECUTE ON  [dbo].[vspVPAllowExportPrintRPRun] TO [public]
GO
