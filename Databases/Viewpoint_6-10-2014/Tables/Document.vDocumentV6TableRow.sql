CREATE TABLE [Document].[vDocumentV6TableRow]
(
[DocumentV6TableRowId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[TableName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[TableKeyId] [bigint] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentV6TableRow_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentV6TableRow_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentV6TableRow_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentV6TableRow_Update ON [Document].vDocumentV6TableRow
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
	FROM Document.vDocumentV6TableRow dr
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[DocumentV6TableRowId]) +1
									ELSE i.[Version]
									END,		
				i.[DocumentV6TableRowId]
		FROM Document.vDocumentV6TableRow d
			JOIN inserted i ON i.[DocumentV6TableRowId] = d.[DocumentV6TableRowId]
		) derive ON derive.[DocumentV6TableRowId] = dr.[DocumentV6TableRowId];
END
GO
ALTER TABLE [Document].[vDocumentV6TableRow] ADD CONSTRAINT [PK_vDocumentV6TableRow] PRIMARY KEY CLUSTERED  ([DocumentV6TableRowId]) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentV6TableRow] WITH NOCHECK ADD CONSTRAINT [FK_vDocumentV6TableRow_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vDocumentV6TableRow] NOCHECK CONSTRAINT [FK_vDocumentV6TableRow_vDocument]
GO
