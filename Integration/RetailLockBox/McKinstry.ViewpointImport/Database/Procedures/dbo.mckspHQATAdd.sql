USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspHQATAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspHQATAdd]
GO

-- **************************************************************
--  PURPOSE: Adds new Attachment record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/27/2015  Created stored procedure
--    03/27/2015  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspHQATAdd]
	@Company tinyint = NULL
	,@HeaderKeyID bigint = NULL
	,@TransactionDate smalldatetime = NULL
	,@Description varchar(30)
	,@Module varchar(30)
	,@FormName varchar(30)
	,@TableName varchar(128)
	,@AttachmentTypeID int = NULL
	,@ImageFileName nvarchar(512) = NULL
	,@AddedBy nvarchar(128) = NULL
	,@KeyID int OUTPUT
	,@UniqueAttchID uniqueidentifier OUTPUT
	,@AttachmentFilePath varchar(512) OUTPUT
	,@Message varchar(512) OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @AttachParamsCheck bit, @AttachCheck bit

-- Attachment variables
DECLARE @KeyField varchar(500), @AddDate [dbo].[bDate], @attid int, @uniqueattchid uniqueidentifier, @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @IsEmail [dbo].[bYN], @msg varchar(100), 
	@ImageFilePath varchar(512), @ImageFullFilePath nvarchar(max)

SELECT @rcode = -1, @RetVal = -1, @KeyID = -1, @UniqueAttchID = NULL, @AttachmentFilePath = NULL, @AttachParamsCheck = 1, @AttachCheck = 1 

IF @TransactionDate = NULL SET @TransactionDate = GETDATE()

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @HeaderKeyID IS NULL SET @HeaderKeyID = 0
IF @HeaderKeyID = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @ImageFileName IS NULL SET @ImageFileName = ''
IF  Len(RTrim(@ImageFileName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @Module IS NULL SET @Module = ''
IF  Len(RTrim(@Module)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @FormName IS NULL SET @FormName = ''
IF  Len(RTrim(@FormName)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @TableName IS NULL SET @TableName = ''
IF  Len(RTrim(@TableName)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @AddedBy IS NULL SET @AddedBy = ''
IF  Len(RTrim(@AddedBy)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

IF @AttachmentTypeID = 0
    BEGIN
	 SET @AttachmentTypeID = NULL
    END

SET @AttachParamsCheck = 0

----------------------------------------------
-- Set Attachment Variables
----------------------------------------------

SELECT	@AddDate = GETDATE()
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@IsEmail = 'N'
		,@KeyField = 'KeyID=' + CAST(@HeaderKeyID as varchar(max))

SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
		,@ImageFilePath = [dbo].[mfnDMAttachmentPath] (@Company, @Module, @FormName, @TransactionDate)
		,@ImageFullFilePath = @ImageFilePath + '\' + @ImageFileName

-- Create and assign attachment variables
DECLARE @FilePathPart varchar(512), @FileSuffix nvarchar(100), @AttachCount int, @FileType nvarchar(10)

SET @FileType = RIGHT(@ImageFullFilePath, CHARINDEX('.', REVERSE('.' + @ImageFullFilePath)))
SET @FilePathPart = REPLACE(@ImageFullFilePath, @FileType, '')
SET @AttachCount = (SELECT COUNT (*) FROM HQAT WHERE DocName LIKE @FilePathPart + '%')
SELECT @FileSuffix = (CASE WHEN @AttachCount > 0 THEN '_' + CAST((@AttachCount + 1) as varchar(100)) + @FileType ELSE @FileType END)
SET @ImageFullFilePath = @FilePathPart + @FileSuffix

BEGIN TRY
BEGIN TRANSACTION Trans_addAttachment

EXECUTE @rcode = [dbo].[vspHQATInsert] 
   @Company
  ,@FormName
  ,@KeyField
  ,@Description
  ,@AddedBy
  ,@AddDate
  ,@ImageFullFilePath
  ,@TableName
  ,@ImageFileName
  ,@attid OUTPUT
  ,@uniqueattchid OUTPUT
  ,@docattchyn
  ,@createAsStandAloneAttachment
  ,@AttachmentTypeID
  ,@IsEmail
  ,@msg OUTPUT

  SELECT @UniqueAttchID = @uniqueattchid, @KeyID = @attid
  SET @AttachmentFilePath = (CASE WHEN @KeyID > 0 THEN @ImageFullFilePath ELSE NULL END)

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAttachment
	    SELECT @rcode=1, @AttachCheck=1
	    GOTO ExitProc
	END

COMMIT TRANSACTION Trans_addAttachment
SELECT @rcode=0, @AttachCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAttachment
	SELECT @rcode=1, @AttachCheck=1
END CATCH

ExitProc:

SET @Message = 'Procedure executed.'

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0))
BEGIN
	SELECT @RetVal=0 
	SELECT @Message = 'Attachment record created successfully.'
	GOTO Final
END
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=1 
	SELECT @Message = 'No records created.  Missing attachment parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1))
BEGIN
	SELECT @RetVal=2  
	SELECT @Message = 'No records created.  Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 

GO


