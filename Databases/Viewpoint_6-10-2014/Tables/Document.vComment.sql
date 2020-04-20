CREATE TABLE [Document].[vComment]
(
[CommentId] [uniqueidentifier] NOT NULL CONSTRAINT [DF_vComment_CommentId] DEFAULT (newid()),
[CommentType] [smallint] NOT NULL,
[CommentDate] [datetime] NOT NULL,
[CommentText] [nvarchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[ParticipantId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[V6Id] [bigint] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vComment_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vComment_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vComment_Version] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	5/29/2013
* Created By:	AR 
* Modified By:		
*		     
* Description: Trigger to handle filling out the table footer
*
* Inputs: 
*
* Outputs:
*
*************************************************/
CREATE TRIGGER Document.TR_vComment_Update ON [Document].vComment
FOR UPDATE
AS 
BEGIN

SET NOCOUNT ON;
	DECLARE @bUpdateDate	BIT,
			@bUpdateUser	BIT,
			@bVersion		BIT;
	
	IF UPDATE([DBUpdatedDate])
	BEGIN 
		SET @bUpdateDate= 1;
	END
	ELSE 
	BEGIN
		SET @bUpdateDate = 0;
	END 

	IF UPDATE([UpdatedByUser])
	BEGIN 
		SET @bUpdateUser= 1;
	END
	ELSE 
	BEGIN
		SET @bUpdateUser = 0;
	END 

	IF UPDATE([Version])
	BEGIN 
		SET @bVersion= 1;
	END
	ELSE 
	BEGIN
		SET @bVersion = 0;
	END 

	UPDATE co
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vComment co
		-- deriving up a table for version, so we can increment it
	JOIN (
		SELECT	[DBUpdatedDate] =	CASE WHEN @bUpdateDate = 0
										THEN GETDATE()
									ELSE 
										i.[DBUpdatedDate]
									END,

				[UpdatedByUser] =	CASE WHEN @bUpdateUser = 0
										THEN  SUSER_NAME()
									ELSE i.[UpdatedByUser]
									END,

				[NextVersion] =		CASE WHEN @bVersion = 0 
										THEN MAX(c.[Version]) OVER(PARTITION BY c.[CommentId]) +1
									ELSE i.[Version]
									END,		
				i.CommentId
		FROM Document.vComment c
			JOIN inserted i ON i.CommentId = c.CommentId
		) derive ON derive.CommentId = co.CommentId;
END
GO
ALTER TABLE [Document].[vComment] ADD CONSTRAINT [PK_vComment] PRIMARY KEY CLUSTERED  ([CommentId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vComment_DocumentParticipant] ON [Document].[vComment] ([DocumentId], [ParticipantId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vComment_V6Id] ON [Document].[vComment] ([DocumentId], [V6Id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vComment] WITH NOCHECK ADD CONSTRAINT [FK_vComment_vCommentType] FOREIGN KEY ([CommentType]) REFERENCES [Document].[vCommentType] ([CommentTypeId])
GO
ALTER TABLE [Document].[vComment] WITH NOCHECK ADD CONSTRAINT [FK_Comment_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vComment] WITH NOCHECK ADD CONSTRAINT [FK_Comment_Participant] FOREIGN KEY ([ParticipantId]) REFERENCES [Document].[vParticipant] ([ParticipantId])
GO
ALTER TABLE [Document].[vComment] NOCHECK CONSTRAINT [FK_vComment_vCommentType]
GO
ALTER TABLE [Document].[vComment] NOCHECK CONSTRAINT [FK_Comment_Document]
GO
ALTER TABLE [Document].[vComment] NOCHECK CONSTRAINT [FK_Comment_Participant]
GO
