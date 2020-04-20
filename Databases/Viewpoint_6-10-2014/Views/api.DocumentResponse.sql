SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentResponse]
	AS SELECT 
	[DocumentResponseId],
	[DocumentId],
	[ParticipantId],
	[Response],
	[KeyID],
	[CreatedByUser],
	[DBCreatedDate],
	[UpdatedByUser],
	[DBUpdatedDate],
	[Version]
	 FROM Document.DocumentResponse
GO
