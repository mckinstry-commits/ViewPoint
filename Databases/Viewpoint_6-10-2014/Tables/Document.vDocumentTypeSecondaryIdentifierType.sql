CREATE TABLE [Document].[vDocumentTypeSecondaryIdentifierType]
(
[DocumentSecondaryIdentifierTypeId] [uniqueidentifier] NOT NULL,
[DocumentTypeId] [uniqueidentifier] NOT NULL,
[DocumentTypeName] [nvarchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[SecondaryIdentifierTypeId] [uniqueidentifier] NOT NULL,
[IdentifierName] [nvarchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[UseDescription] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentTypeSecondaryIdentifierType_UseDescription] DEFAULT ('N'),
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentTypeSecondaryIdentifierType_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentTypeSecondaryIdentifierType_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentTypeSecondaryIdentifierType_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentTypeSecondaryIdentifierType_Update ON [Document].vDocumentTypeSecondaryIdentifierType
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

	UPDATE dt
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vDocumentTypeSecondaryIdentifierType dt
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[DocumentSecondaryIdentifierTypeId]) +1
									ELSE i.[Version]
									END,		
				i.[DocumentSecondaryIdentifierTypeId]
		FROM Document.vDocumentTypeSecondaryIdentifierType d
			JOIN inserted i ON i.[DocumentSecondaryIdentifierTypeId] = d.[DocumentSecondaryIdentifierTypeId]
		) derive ON derive.[DocumentSecondaryIdentifierTypeId] = dt.[DocumentSecondaryIdentifierTypeId];
END
GO
ALTER TABLE [Document].[vDocumentTypeSecondaryIdentifierType] ADD CONSTRAINT [PK_DocumentTypeSecondaryIdentifierType] PRIMARY KEY CLUSTERED  ([DocumentSecondaryIdentifierTypeId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DocumentTypeSecondaryIdentifierType_DocumentType] ON [Document].[vDocumentTypeSecondaryIdentifierType] ([DocumentTypeId], [SecondaryIdentifierTypeId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentTypeSecondaryIdentifierType] WITH NOCHECK ADD CONSTRAINT [FK_DocumentTypeSecondaryIdentifierType_DocumentType] FOREIGN KEY ([DocumentTypeId], [DocumentTypeName]) REFERENCES [Document].[vDocumentType] ([DocumentTypeId], [DocumentTypeName])
GO
ALTER TABLE [Document].[vDocumentTypeSecondaryIdentifierType] WITH NOCHECK ADD CONSTRAINT [FK_DocumentTypeSecondaryIdentifierType_SecondaryIdentifier] FOREIGN KEY ([SecondaryIdentifierTypeId], [IdentifierName]) REFERENCES [Document].[vSecondaryIdentifierType] ([SecondaryIdentifierTypeId], [IdentifierName])
GO
ALTER TABLE [Document].[vDocumentTypeSecondaryIdentifierType] NOCHECK CONSTRAINT [FK_DocumentTypeSecondaryIdentifierType_DocumentType]
GO
ALTER TABLE [Document].[vDocumentTypeSecondaryIdentifierType] NOCHECK CONSTRAINT [FK_DocumentTypeSecondaryIdentifierType_SecondaryIdentifier]
GO
