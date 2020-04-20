CREATE TABLE [Document].[vActivity]
(
[ActivityId] [uniqueidentifier] NOT NULL,
[ActivityName] [nvarchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[ActivityDate] [datetime] NOT NULL CONSTRAINT [DF_vActivity_ActivityDate] DEFAULT (getdate()),
[ParticipantId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[CommentId] [uniqueidentifier] NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vActivity_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vActivity_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vActivity_Version] DEFAULT ((1))
) ON [PRIMARY]
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
CREATE TRIGGER Document.TR_vActivity_Update ON [Document].[vActivity]
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

	UPDATE act
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.[vActivity] act
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
										THEN MAX(a.[Version]) OVER(PARTITION BY a.[ActivityId] ) +1
									ELSE i.[Version]
									END,		
				i.[ActivityId]
		FROM Document.[vActivity] a
			JOIN inserted i ON i.[ActivityId] = a.[ActivityId]
		) derive ON derive.[ActivityId] = act.[ActivityId];
END
GO
ALTER TABLE [Document].[vActivity] ADD CONSTRAINT [PK_vActivity] PRIMARY KEY CLUSTERED  ([ActivityId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vActivity_Comment] ON [Document].[vActivity] ([CommentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vActivity_Document] ON [Document].[vActivity] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vActivity_Participant] ON [Document].[vActivity] ([ParticipantId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vActivity] WITH NOCHECK ADD CONSTRAINT [FK_DocumentActivity_Comment] FOREIGN KEY ([CommentId]) REFERENCES [Document].[vComment] ([CommentId])
GO
ALTER TABLE [Document].[vActivity] WITH NOCHECK ADD CONSTRAINT [FK_Activity_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vActivity] WITH NOCHECK ADD CONSTRAINT [FK_Activity_Participant] FOREIGN KEY ([ParticipantId]) REFERENCES [Document].[vParticipant] ([ParticipantId])
GO
ALTER TABLE [Document].[vActivity] NOCHECK CONSTRAINT [FK_DocumentActivity_Comment]
GO
ALTER TABLE [Document].[vActivity] NOCHECK CONSTRAINT [FK_Activity_Document]
GO
ALTER TABLE [Document].[vActivity] NOCHECK CONSTRAINT [FK_Activity_Participant]
GO
