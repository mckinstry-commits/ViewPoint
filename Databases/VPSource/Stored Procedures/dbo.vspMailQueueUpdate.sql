SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspMailQueueUpdate]
/************************************************************
* CREATED:     4/6/06  SDE
* MODIFIED:    
*
* USAGE:
*	Updates a Message that is already in the Queue
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
(
	@To varchar(3000),
	@CC varchar(3000),
	@BCC varchar(3000),
	@From varchar(3000),
	@Subject varchar(3000),
	@Body text,
	@Attempts int,
	@FailureDate datetime,
	@FailureReason varchar(3000),
	@Original_MailQueueID int,
	@Original_Attempts int,
	@Original_BCC varchar(3000),
	@Original_CC varchar(3000),
	@Original_FailureDate datetime,
	@Original_FailureReason varchar(3000),
	@Original_From varchar(3000),
	@Original_Subject varchar(3000),
	@Original_To varchar(3000),
	@MailQueueID int
)
AS
	SET NOCOUNT OFF;
UPDATE vMailQueue SET [To] = @To, CC = @CC, BCC = @BCC, [From] = @From, Subject = @Subject, Body = @Body, Attempts = @Attempts, FailureDate = @FailureDate, FailureReason = @FailureReason WHERE (MailQueueID = @Original_MailQueueID) AND (Attempts = @Original_Attempts OR @Original_Attempts IS NULL AND Attempts IS NULL) AND (BCC = @Original_BCC OR @Original_BCC IS NULL AND BCC IS NULL) AND (CC = @Original_CC OR @Original_CC IS NULL AND CC IS NULL) AND (FailureDate = @Original_FailureDate OR @Original_FailureDate IS NULL AND FailureDate IS NULL) AND (FailureReason = @Original_FailureReason OR @Original_FailureReason IS NULL AND FailureReason IS NULL) AND ([From] = @Original_From OR @Original_From IS NULL AND [From] IS NULL) AND (Subject = @Original_Subject OR @Original_Subject IS NULL AND Subject IS NULL) AND ([To] = @Original_To);
	SELECT MailQueueID, [To], CC, BCC, [From], Subject, Body, Attempts, FailureDate, FailureReason FROM vMailQueue with (nolock) WHERE (MailQueueID = @MailQueueID)

GO
GRANT EXECUTE ON  [dbo].[vspMailQueueUpdate] TO [public]
GRANT EXECUTE ON  [dbo].[vspMailQueueUpdate] TO [VCSPortal]
GO
