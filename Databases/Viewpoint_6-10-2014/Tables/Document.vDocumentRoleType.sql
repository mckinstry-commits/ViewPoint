CREATE TABLE [Document].[vDocumentRoleType]
(
[DocumentRoleTypeId] [uniqueidentifier] NOT NULL,
[RoleName] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentRoleType_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentRoleType_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentRoleType_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentRoleType_Update ON [Document].vDocumentRoleType
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

	UPDATE dr
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vDocumentRoleType dr
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[DocumentRoleTypeId]) +1
									ELSE i.[Version]
									END,		
				i.[DocumentRoleTypeId]
		FROM Document.vDocumentRoleType d
			JOIN inserted i ON i.[DocumentRoleTypeId] = d.[DocumentRoleTypeId]
		) derive ON derive.[DocumentRoleTypeId] = dr.[DocumentRoleTypeId];
END
GO
ALTER TABLE [Document].[vDocumentRoleType] ADD CONSTRAINT [PK_DocumentRoleType] PRIMARY KEY CLUSTERED  ([DocumentRoleTypeId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocumentParticipantRoleType_KeyID] ON [Document].[vDocumentRoleType] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocumentParticipantRoleType_RoleNameDocumentRoleId] ON [Document].[vDocumentRoleType] ([RoleName], [DocumentRoleTypeId]) ON [PRIMARY]
GO
