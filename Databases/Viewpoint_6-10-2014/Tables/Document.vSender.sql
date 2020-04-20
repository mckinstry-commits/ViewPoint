CREATE TABLE [Document].[vSender]
(
[SenderId] [uniqueidentifier] NOT NULL,
[FirstName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[LastName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[Email] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DisplayName] [nvarchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[Title] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vSender_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vSender_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vSender_Version] DEFAULT ((1))
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
CREATE TRIGGER Document.TR_vSender_Update ON [Document].[vSender]
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

	UPDATE sd
	SET [DBUpdatedDate] = derive.[DBUpdatedDate],
		[UpdatedByUser] = derive.[UpdatedByUser],
		[Version] = derive.[NextVersion]
	FROM Document.[vSender] sd
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
										THEN MAX(s.[Version]) OVER(PARTITION BY s.[SenderId]) +1
									ELSE i.[Version]
									END,		
				i.[SenderId]
		FROM Document.[vSender] s
			JOIN inserted i ON i.[SenderId] = s.[SenderId]
		) derive ON derive.[SenderId] = sd.[SenderId];
END
GO
ALTER TABLE [Document].[vSender] ADD CONSTRAINT [PK_vSender] PRIMARY KEY CLUSTERED  ([SenderId]) ON [PRIMARY]
GO
