SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspInsertPortidocAttachment]
@FileName NVARCHAR(128),
@DocumentData VARBINARY(MAX),
@DocumentSize int,
@ContentType nvarchar(32),
@DocumentId uniqueidentifier ,
@ParticipantId uniqueidentifier,
@CreateUser nvarchar(128),
@AttachmentId uniqueidentifier OUTPUT

AS  
BEGIN
	SET NOCOUNT ON;	
	
	SELECT @AttachmentId = NEWID();
	
	INSERT INTO Document.DocumentAttachment ( AttachmentId, FullName, AttachmentData, AttachmentSize, ContentType, DocumentId, DocumentImage, ParticipantId, CreatedByUser, DBCreatedDate, Version)
	VALUES (NEWID(), @FileName , @DocumentData, @DocumentSize, @ContentType, @DocumentId, 0, @ParticipantId, @CreateUser, GETUTCDATE(), 1);

END
GO
GRANT EXECUTE ON  [dbo].[vspInsertPortidocAttachment] TO [public]
GO
