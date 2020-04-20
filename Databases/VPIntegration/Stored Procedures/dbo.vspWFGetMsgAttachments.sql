SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 2/21/2008
-- Description:	Gets attachment information for a given record
-- =============================================
CREATE PROCEDURE [dbo].[vspWFGetMsgAttachments] 
	-- Add the parameters for the stored procedure here
	@RecordID int = null, 
	@Type varchar = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	if @Type = 'A' --archive
		SELECT OrigFileName AS [FileName], [Description], DocName AS FileLocation, 'Y' AS IsVPAttachment, AttachmentID AS AttachmentID 
		FROM HQAT
		INNER JOIN vMailQueueAttchLink ON vMailQueueAttchLink.AttachID = HQAT.AttachmentID
		WHERE vMailQueueAttchLink.MailID = @RecordID
		UNION ALL
		SELECT NULL as [FileName], NULL AS [Description], AttachFile AS FileLocation, 'N' AS IsVPAttachment, null AS AttachmentID
		FROM vMailQueueAttchFiles
		WHERE vMailQueueAttchFiles.MailID = @RecordID

	if @Type = 'M' --message
		SELECT OrigFileName AS [FileName], [Description], DocName AS FileLocation, 'Y' AS IsVPAttachment, AttachmentID AS AttachmentID  
		FROM HQAT
		INNER JOIN vWFMailAttchLink ON vWFMailAttchLink.AttachID = HQAT.AttachmentID
		WHERE vWFMailAttchLink.MailID = @RecordID
		UNION ALL
		SELECT NULL as [FileName], NULL AS [Description], AttachFile AS FileLocation, 'N' AS IsVPAttachment, null AS AttachmentID
		FROM vWFMailAttchFiles
		WHERE vWFMailAttchFiles.MailID = @RecordID
END

GO
GRANT EXECUTE ON  [dbo].[vspWFGetMsgAttachments] TO [public]
GO
