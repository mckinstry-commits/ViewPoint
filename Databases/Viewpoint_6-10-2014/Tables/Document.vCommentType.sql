CREATE TABLE [Document].[vCommentType]
(
[CommentTypeId] [smallint] NOT NULL,
[CommentType] [varchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vCommentType_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vCommentType_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vCommentType_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vCommentType_Update ON [Document].[vCommentType]
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

	UPDATE ct
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.[vCommentType] ct
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
										THEN MAX(c.[Version]) OVER(PARTITION BY c.[CommentTypeId]) +1
									ELSE i.[Version]
									END,		
				i.[CommentTypeId]
		FROM Document.[vCommentType] c
			JOIN inserted i ON i.[CommentTypeId] = c.[CommentTypeId]
		) derive ON derive.[CommentTypeId] = ct.[CommentTypeId];
END
GO
ALTER TABLE [Document].[vCommentType] ADD CONSTRAINT [PK_vCommentType] PRIMARY KEY CLUSTERED  ([CommentTypeId]) ON [PRIMARY]
GO
