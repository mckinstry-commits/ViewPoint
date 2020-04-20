CREATE TABLE [Document].[vRelatedDocument]
(
[RelatedDocumentId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[AssociatedDocumentId] [uniqueidentifier] NOT NULL,
[KeyId] [bigint] NOT NULL IDENTITY(1, 1),
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vRelatedDocument_CreatedByUser] DEFAULT (suser_name()),
[DBCreateDate] [datetime] NOT NULL CONSTRAINT [DF_vRelatedDocument_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vRelatedDocument_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vRelatedDocument_Update ON [Document].vRelatedDocument
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

	UPDATE rd
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vRelatedDocument rd
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[RelatedDocumentId]) +1
									ELSE i.[Version]
									END,		
				i.[RelatedDocumentId]
		FROM Document.vRelatedDocument d
			JOIN inserted i ON i.[RelatedDocumentId] = d.[RelatedDocumentId]
		) derive ON derive.[RelatedDocumentId] = rd.[RelatedDocumentId];
END
GO
ALTER TABLE [Document].[vRelatedDocument] ADD CONSTRAINT [PK_vRelatedDocument] PRIMARY KEY CLUSTERED  ([RelatedDocumentId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_RelatedDocument_DocumentAssociatedDocument] ON [Document].[vRelatedDocument] ([DocumentId], [AssociatedDocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vRelatedDocument] WITH NOCHECK ADD CONSTRAINT [FK_vReleatedDocument_vDocumentAssociated] FOREIGN KEY ([AssociatedDocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vRelatedDocument] WITH NOCHECK ADD CONSTRAINT [FK_vReleatedDocument_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vRelatedDocument] NOCHECK CONSTRAINT [FK_vReleatedDocument_vDocumentAssociated]
GO
ALTER TABLE [Document].[vRelatedDocument] NOCHECK CONSTRAINT [FK_vReleatedDocument_vDocument]
GO
