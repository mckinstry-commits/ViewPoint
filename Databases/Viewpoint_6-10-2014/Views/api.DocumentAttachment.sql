SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentAttachment]
	AS 
	SELECT [AttachmentId], [FullName], [AttachmentData], [AttachmentSize], [ContentType], [DocumentId], [DocumentImage], [ParticipantId], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] 
	FROM [Document].DocumentAttachment
GO
