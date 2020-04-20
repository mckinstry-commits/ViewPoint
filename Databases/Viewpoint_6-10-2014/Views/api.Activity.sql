SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[Activity]
	AS SELECT [ActivityId], [ActivityName], [ActivityDate], [ParticipantId], [DocumentId], [CommentId], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.Activity
GO
