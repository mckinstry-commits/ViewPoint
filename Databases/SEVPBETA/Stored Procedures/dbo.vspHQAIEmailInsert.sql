SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspHQAIEmailInsert]
/*******************************************************************************
* CREATED BY: CC 03/04/10 Issue #130945 - Add email specific values to HQAI
* MODIFIED BY: 
*		
* 
* Inserts a record into HQ Attachment table - called from frmAttachmentDetail
* 
* Inputs:
*
* Output:	
*	@attid			Attachment ID#
*	@msg			Error message	
*
* Return code:
*	@rcode			0 = success, 1 = failure
*
********************************************************************************/

(@attachmentID INT, @emailSubject VARCHAR(1500) = NULL, @receivedDate DATETIME =NULL, @sentDate DATETIME = NULL, 
@fromAddress VARCHAR(200) = NULL, @ToAddresses VARCHAR(2000) = NULL, @CCAddresses VARCHAR(2000) = NULL)

AS
BEGIN     
   SET NOCOUNT ON;
   
   WITH NextIndexSequence(Seq)
   AS
   (
		SELECT MAX(IndexSeq) 
		FROM HQAI 
		WHERE AttachmentID = @attachmentID
   )
   
   INSERT INTO HQAI (AttachmentID, IndexSeq, EmailSubject, EmailReceivedDate, EmailSentDate, EmailFromAddress, EmailToAddresses, EmailCCAddresses, IsEmailIndex, CustomYN)
   SELECT @attachmentID, Seq + 1, @emailSubject, @receivedDate, @sentDate, @fromAddress, @ToAddresses, @CCAddresses, 1, 'N'
   FROM NextIndexSequence;
   
END

GO
GRANT EXECUTE ON  [dbo].[vspHQAIEmailInsert] TO [public]
GO
