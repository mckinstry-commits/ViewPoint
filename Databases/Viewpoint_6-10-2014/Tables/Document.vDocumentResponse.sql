CREATE TABLE [Document].[vDocumentResponse]
(
[DocumentResponseId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[ParticipantId] [uniqueidentifier] NOT NULL,
[Response] [xml] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentResponse_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentResponse_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Processed] [bit] NOT NULL CONSTRAINT [DF_vDocumentResponse_Processed] DEFAULT ((0)),
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentResponse_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vDocumentResponse_Update ON [Document].vDocumentResponse
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
	FROM Document.vDocumentResponse dr
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
										THEN MAX(d.[Version]) OVER(PARTITION BY d.[DocumentResponseId] ) +1
									ELSE i.[Version]
									END,		
				i.[DocumentResponseId]
		FROM Document.vDocumentResponse d
			JOIN inserted i ON i.[DocumentResponseId] = d.[DocumentResponseId]
		) derive ON derive.[DocumentResponseId] = dr.[DocumentResponseId];
END
GO
ALTER TABLE [Document].[vDocumentResponse] ADD CONSTRAINT [PK_vDocumentResponse] PRIMARY KEY CLUSTERED  ([DocumentResponseId]) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentResponse] WITH NOCHECK ADD CONSTRAINT [FK_vResponse_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vDocumentResponse] WITH NOCHECK ADD CONSTRAINT [FK_vResponse_vParticipant] FOREIGN KEY ([ParticipantId]) REFERENCES [Document].[vParticipant] ([ParticipantId])
GO
ALTER TABLE [Document].[vDocumentResponse] NOCHECK CONSTRAINT [FK_vResponse_vDocument]
GO
ALTER TABLE [Document].[vDocumentResponse] NOCHECK CONSTRAINT [FK_vResponse_vParticipant]
GO
