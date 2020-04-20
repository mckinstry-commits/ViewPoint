SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspWFNFPurgeSentNotifications]
/*******************************************************************
* CREATED: CC 1/27/2008 - Purge sent notifications for a given job
*			
* LAST MODIFIED: 
*
* INPUT PARAMS: 
*	@JobName - Notifier Job name to purge records for
*
* OUTPUT PARAMS: @AffectedRows - Number of rows deleted
*
********************************************************************/
(@JobName VARCHAR(60), @AffectedRows int OUTPUT)

AS
BEGIN
	SET NOCOUNT ON

	DELETE 
	FROM WFSentNotifications
	WHERE JobName = @JobName

	SELECT @AffectedRows = @@ROWCOUNT
END
GO
GRANT EXECUTE ON  [dbo].[vspWFNFPurgeSentNotifications] TO [public]
GO
