CREATE TABLE [Document].[vDocumentType]
(
[DocumentTypeId] [uniqueidentifier] NOT NULL,
[DocumentTypeName] [nvarchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DocumentTypeDescription] [nvarchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentType_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentType_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentType_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentType_Update ON [Document].vDocumentType
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
	FROM Document.vDocumentType dt
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.DocumentTypeId ) +1
									ELSE i.[Version]
									END,		
				i.DocumentTypeId
		FROM Document.vDocumentType d
			JOIN inserted i ON i.DocumentTypeId = d.DocumentTypeId
		) derive ON derive.DocumentTypeId = dt.DocumentTypeId;
END
GO
ALTER TABLE [Document].[vDocumentType] ADD CONSTRAINT [PK_vDocumentType] PRIMARY KEY CLUSTERED  ([DocumentTypeId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocumentType_DocumentTypeIdName] ON [Document].[vDocumentType] ([DocumentTypeId], [DocumentTypeName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocumentType_DocumentTypeName] ON [Document].[vDocumentType] ([DocumentTypeName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDocumentType_Form] ON [Document].[vDocumentType] ([Form]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
