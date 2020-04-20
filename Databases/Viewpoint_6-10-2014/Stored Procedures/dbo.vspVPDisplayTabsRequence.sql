SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: Chris G 03/29/2011 B-02317
* MODIFIED BY: 
*
*
*
*
* Usage: Resequences the DisplayTabs TabNumber column so that is 1-6. The
*		 user is allowed to enter whatever they want, however, the system
*		 requires the TabNumbers to be 1-6 sequencially.
*
* Input params:
*	@username
*
* Output params:
*	List of Displays
*
* Return code:
*	
************************************************************/
CREATE PROCEDURE [dbo].[vspVPDisplayTabsRequence] 
	@DisplayID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @tabNumber smallint
	SET @tabNumber = 0

	UPDATE VPDisplayTabs 
	SET @tabNumber = TabNumber = @tabNumber + 1
	WHERE KeyID IN
		(SELECT TOP 10000 KeyID -- NOTE: T-Sql requires 'top' for order by, so set it rediculously high so we can change the tab count elsewhere
		 FROM VPDisplayTabs 
		 WHERE DisplayID = @DisplayID 
		 ORDER BY TabNumber)
END

GO
GRANT EXECUTE ON  [dbo].[vspVPDisplayTabsRequence] TO [public]
GO
