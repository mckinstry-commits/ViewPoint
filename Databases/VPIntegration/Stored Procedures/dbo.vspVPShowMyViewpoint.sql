SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
*				CC 2011-05-06 - enable my viewpoint/work centers by default
* Create date:  10/21/2008
* Description:	Get whether or not to display My Viewpoint tab
*
*	Inputs:
*
*	Outputs:
*	@ShowMyViewpoint		bYN indicating whether or not to show the tab
*	
*	Returns:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPShowMyViewpoint]
	-- Add the parameters for the stored procedure here
	@ShowMyViewpoint bYN = 'Y' OUTPUT,
	@NumberOfTabs int = 6 OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT 
		TOP 1 
			@ShowMyViewpoint = COALESCE(ShowMyViewpoint, 'Y'),
			@NumberOfTabs = COALESCE(NumberOfWorkCenterTabs, 6)
		FROM DDVS;
END


GO
GRANT EXECUTE ON  [dbo].[vspVPShowMyViewpoint] TO [public]
GO
