SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[Comment]
	AS 
		SELECT	[CommentId], [CommentType], [CommentDate], [CommentText], [ParticipantId], [DocumentId], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version]
		FROM Document.Comment
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************************
	Create By: Adam Rink
	Create Date: 11/13/2012

	Description: Handle inserts from api.Comment because API will not include the V6Id
				V6Id is need for the V6 application to function properly
	Updated 11/21/2012: JF Commented out Trx logic and calls.
						This was causing records to commit even when being rolled back by code.
						Issue isolated to Build Server environment.
						Need to isolate why this Trx not enlisting in either
						ADO.NET trx or System.Transaction started on client
						when run on build server instance
	Updated 4/17/2013: AR - V6Id is now a Seq of Document because of the form, we need to reset
						number with a new document.
**********************************************************************/
CREATE TRIGGER [api].[TR_APIComment_Insert] ON [api].[Comment]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	BEGIN TRY
		-- BEGIN TRAN
			INSERT INTO [Document].[Comment]
				   ([CommentId]
				   ,[CommentType]
				   ,[CommentDate]
				   ,[CommentText]
				   ,[ParticipantId]
				   ,[DocumentId]
				   ,[CreatedByUser]
				   ,[DBCreatedDate]
				   ,[UpdatedByUser]
				   ,[DBUpdatedDate]
				   ,[Version]
				   ,[V6Id]
				   )
			SELECT  i.[CommentId]
				   ,i.[CommentType]
				   ,i.[CommentDate]
				   ,i.[CommentText]
				   ,i.[ParticipantId]
				   ,i.[DocumentId]
				   ,i.[CreatedByUser]
				   ,i.[DBCreatedDate]
				   ,i.[UpdatedByUser]
				   ,i.[DBUpdatedDate]
				   ,i.[Version]
				   --give the next series of the rows
				   ,ISNULL(d.MaxId,0) 
						+ ROW_NUMBER() OVER (PARTITION BY i.[DocumentId] ORDER BY i.CommentId)
			FROM inserted i
				OUTER APPLY 
					(	SELECT MAX(V6Id) MaxId 
						FROM [Document].[Comment] c 
						WHERE  c.[DocumentId] = i.[DocumentId]
					) d
					
				
		-- COMMIT TRAN ;
	END TRY
	BEGIN CATCH
		-- IF @@TRANCOUNT <> 0 BEGIN ROLLBACK TRAN; END 
	END CATCH 
END
GO
