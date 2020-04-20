CREATE TABLE [Document].[vDocument]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[Title] [nvarchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[SenderId] [uniqueidentifier] NOT NULL,
[DocumentTypeId] [uniqueidentifier] NOT NULL,
[DueDate] [datetime] NULL,
[SentDate] [datetime] NOT NULL,
[DocumentDisplay] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[CompanyId] [uniqueidentifier] NOT NULL,
[State] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocument_CreatedByUser] DEFAULT (suser_name()),
[UniqueAttchID] [uniqueidentifier] NULL,
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocument_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocument_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocument_Update ON [Document].vDocument
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

	UPDATE do
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.vDocument do
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.DocumentId) +1
									ELSE i.[Version]
									END,		
				i.DocumentId
		FROM Document.vDocument d
			JOIN inserted i ON i.DocumentId = d.DocumentId
		) derive ON derive.DocumentId = do.DocumentId;
END
GO
ALTER TABLE [Document].[vDocument] ADD CONSTRAINT [PK_vDocument] PRIMARY KEY CLUSTERED  ([DocumentId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocument_Company] ON [Document].[vDocument] ([CompanyId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocument_DocumentType] ON [Document].[vDocument] ([DocumentTypeId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocument_DocumentId] ON [Document].[vDocument] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocument_Sender] ON [Document].[vDocument] ([SenderId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Document_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Document].[vCompany] ([CompanyId])
GO
ALTER TABLE [Document].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Document_Document_Document_DocumentType] FOREIGN KEY ([DocumentTypeId]) REFERENCES [Document].[vDocumentType] ([DocumentTypeId])
GO
ALTER TABLE [Document].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Document_Sender] FOREIGN KEY ([SenderId]) REFERENCES [Document].[vSender] ([SenderId])
GO
ALTER TABLE [Document].[vDocument] NOCHECK CONSTRAINT [FK_Document_CompanyId]
GO
ALTER TABLE [Document].[vDocument] NOCHECK CONSTRAINT [FK_Document_Document_Document_DocumentType]
GO
ALTER TABLE [Document].[vDocument] NOCHECK CONSTRAINT [FK_Document_Sender]
GO
