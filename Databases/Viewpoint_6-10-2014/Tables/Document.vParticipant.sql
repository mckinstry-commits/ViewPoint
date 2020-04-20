CREATE TABLE [Document].[vParticipant]
(
[ParticipantId] [uniqueidentifier] NOT NULL,
[FirstName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[LastName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[Email] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DisplayName] [nvarchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[Title] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[CompanyName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CompanyNumber] [tinyint] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[Status] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DocumentRoleTypeId] [uniqueidentifier] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vParticipant_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vParticipant_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vParticipant_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vParticipant_Update ON [Document].vParticipant
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

	UPDATE pt
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vParticipant pt
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
										THEN MAX(p.[Version]) OVER(PARTITION BY p.ParticipantId) +1
									ELSE i.[Version]
									END,		
				i.ParticipantId
		FROM Document.vParticipant p
			JOIN inserted i ON i.ParticipantId = p.ParticipantId
		) derive ON derive.ParticipantId = pt.ParticipantId;
END
GO
ALTER TABLE [Document].[vParticipant] ADD CONSTRAINT [PK_vParticipant] PRIMARY KEY CLUSTERED  ([ParticipantId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vParticipant_DocumentId] ON [Document].[vParticipant] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vParticipant] WITH NOCHECK ADD CONSTRAINT [FK_Participant_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vParticipant] WITH NOCHECK ADD CONSTRAINT [FK_Participant_DocumentRoleType] FOREIGN KEY ([DocumentRoleTypeId]) REFERENCES [Document].[vDocumentRoleType] ([DocumentRoleTypeId])
GO
ALTER TABLE [Document].[vParticipant] NOCHECK CONSTRAINT [FK_Participant_Document]
GO
ALTER TABLE [Document].[vParticipant] NOCHECK CONSTRAINT [FK_Participant_DocumentRoleType]
GO
