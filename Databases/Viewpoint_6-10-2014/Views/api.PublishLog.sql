SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[PublishLog]
	AS SELECT [PublishLogId], [DocumentId], [SuccessFlag], [SendDate], [ReceiveDate], [ErrorMessage] FROM [Document].[PublishLog]
GO
