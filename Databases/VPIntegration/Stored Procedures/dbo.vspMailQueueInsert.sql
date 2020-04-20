SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspMailQueueInsert]
/************************************************************
* CREATED:     4/6/06  SDE
* MODIFIED:    2/19/06 CC -- Add additional columns to statements
*			12/31/2010 Gartht -- Added additional columns to statement (TokenID and VPUserName)
*			11/06/2012 HH - TK-18867 added IsHTML parameter
* USAGE:
*	Inserts a new Message into the Queue
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
	@CC varchar(3000) = Null,
	@BCC varchar(3000) = Null,
	@From varchar(3000) = Null,
	@Subject varchar(3000),
	@Body text,
	@Attempts int = Null,
	@FailureDate datetime = Null,
	@FailureReason varchar(3000) = Null,
	@Source varchar(30) = null,
	@AttachIDs varchar(max) = null,
	@AttachFiles varchar(max) = null,
	@CacheFolder varchar(max) = null,
	@TokenID int = Null,
	@VPUserName bVPUserName = NULL,
	@IsHTML bYN = 'N'
)
AS
	SET NOCOUNT ON;
INSERT INTO vMailQueue([To], CC, BCC, [From], Subject, Body, Attempts, FailureDate, FailureReason, Source, AttachIDs, AttachFiles, CacheFolder, TokenID, VPUserName, IsHTML) VALUES (@To, @CC, @BCC, @From, @Subject, @Body, @Attempts, @FailureDate, @FailureReason, @Source, @AttachIDs, @AttachFiles, @CacheFolder, @TokenID, @VPUserName, @IsHTML);
	SELECT MailQueueID, [To], CC, BCC, [From], Subject, Body, Attempts, FailureDate, FailureReason, Source, AttachIDs, AttachFiles, CacheFolder, TokenID, VPUserName FROM vMailQueue with (nolock) WHERE (MailQueueID = SCOPE_IDENTITY())

GO
GRANT EXECUTE ON  [dbo].[vspMailQueueInsert] TO [public]
GRANT EXECUTE ON  [dbo].[vspMailQueueInsert] TO [VCSPortal]
GO
