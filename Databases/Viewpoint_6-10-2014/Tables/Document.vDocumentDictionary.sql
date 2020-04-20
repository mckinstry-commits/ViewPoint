CREATE TABLE [Document].[vDocumentDictionary]
(
[KeyId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentDictionaryId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[SecondaryIdentifierTypeId] [uniqueidentifier] NOT NULL,
[DictionaryValue] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[Ordinal] [tinyint] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentDictionary_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentDictionary_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentDictionary_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentDictionary_Update ON [Document].vDocumentDictionary
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

	UPDATE dd
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vDocumentDictionary dd
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[DocumentDictionaryId] ) +1
									ELSE i.[Version]
									END,		
				i.[DocumentDictionaryId]
		FROM Document.vDocumentDictionary d
			JOIN inserted i ON i.[DocumentDictionaryId] = d.[DocumentDictionaryId]
		) derive ON derive.[DocumentDictionaryId] = dd.[DocumentDictionaryId];
END
GO
ALTER TABLE [Document].[vDocumentDictionary] ADD CONSTRAINT [PK_DocumentDictionary] PRIMARY KEY CLUSTERED  ([KeyId]) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentDictionary] WITH NOCHECK ADD CONSTRAINT [FK_DocumentDictionary_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vDocumentDictionary] WITH NOCHECK ADD CONSTRAINT [FK_DocumentDictionary_SecondaryIdentifierType] FOREIGN KEY ([SecondaryIdentifierTypeId]) REFERENCES [Document].[vSecondaryIdentifierType] ([SecondaryIdentifierTypeId])
GO
ALTER TABLE [Document].[vDocumentDictionary] NOCHECK CONSTRAINT [FK_DocumentDictionary_Document]
GO
ALTER TABLE [Document].[vDocumentDictionary] NOCHECK CONSTRAINT [FK_DocumentDictionary_SecondaryIdentifierType]
GO
