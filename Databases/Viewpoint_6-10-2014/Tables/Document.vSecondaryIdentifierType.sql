CREATE TABLE [Document].[vSecondaryIdentifierType]
(
[SecondaryIdentifierTypeId] [uniqueidentifier] NOT NULL,
[IdentifierName] [nvarchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vSecondaryIdentifierType_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vSecondaryIdentifierType_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vSecondaryIdentifierType_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vSecondaryIdentifierType_Update ON [Document].[vSecondaryIdentifierType]
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

	UPDATE si
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.[vSecondaryIdentifierType] si
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
										THEN MAX(s.[Version]) OVER(PARTITION BY s.[SecondaryIdentifierTypeId]) +1
									ELSE i.[Version]
									END,		
				i.[SecondaryIdentifierTypeId]
		FROM Document.[vSecondaryIdentifierType] s
			JOIN inserted i ON i.[SecondaryIdentifierTypeId] = s.[SecondaryIdentifierTypeId]
		) derive ON derive.[SecondaryIdentifierTypeId] = si.[SecondaryIdentifierTypeId];
END
GO
ALTER TABLE [Document].[vSecondaryIdentifierType] ADD CONSTRAINT [PK_vSecondaryIdentifierType] PRIMARY KEY CLUSTERED  ([SecondaryIdentifierTypeId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vSecondaryIdentifierType_IdentifierName] ON [Document].[vSecondaryIdentifierType] ([IdentifierName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vSecondaryIdentifierType_IdentifierNameId] ON [Document].[vSecondaryIdentifierType] ([SecondaryIdentifierTypeId], [IdentifierName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
