SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspMailQueueGet]
/************************************************************
* CREATED:     4/6/06  SDE
* MODIFIED:    2/6/08  CC -- added additional columns to select statement
*			 12/31/10  Gartht - Added additional columns to select statement (TokenID and VPUserName).
*			 JayR 2012-08-01 -  Add column IsHTML
* USAGE:
*	Gets Messages from the Queue
*	
*	
*
* CALLED FROM:
*	Viewpoint and Portal  
*
* INPUT PARAMETERS
*    
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
AS
	SET NOCOUNT OFF;
SELECT MailQueueID, [To], CC, BCC, [From], Subject, Body, Attempts, FailureDate, FailureReason, Source, AttachIDs, AttachFiles, CacheFolder, TokenID, VPUserName, IsHTML FROM vMailQueue with (nolock)

GO
GRANT EXECUTE ON  [dbo].[vspMailQueueGet] TO [public]
GRANT EXECUTE ON  [dbo].[vspMailQueueGet] TO [VCSPortal]
GO
