SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[Sender]
	AS SELECT [SenderId], [FirstName], [LastName], [Email], [DisplayName], [Title], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.Sender
GO
