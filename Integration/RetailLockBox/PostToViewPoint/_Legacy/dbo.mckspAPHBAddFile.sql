SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPHBAddFile]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPHBAddFile]
GO

-- **************************************************************
--  PURPOSE: Adds new APHB Attachment records
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    06/19/2014  Created stored procedure
--    06/20/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPHBAddFile]
	@KeyID bigint = NULL
	,@Module varchar(30) = NULL
	,@FormName varchar(30) = NULL
	,@ImageFileName nvarchar(512) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@Company tinyint OUTPUT
	,@InvoiceDate smalldatetime OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @AttachExists bit, @AttachParamsCheck bit, @AttachCheck bit

-- ARBH variables
DECLARE @APRef varchar(15)

-- Attachment variables
DECLARE @keyfield varchar(500), @adddate [dbo].[bDate] ,@tablename varchar(128), @attid int, @uniqueattchid uniqueidentifier, @docattchyn char(1), 
	@Description [dbo].[bDesc], @createAsStandAloneAttachment [dbo].[bYN], @attachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), @ImageFilePath nvarchar(512),
	@ImageFullFilePath nvarchar(max)

SELECT @rcode = -1, @RetVal = -1, 
	@AttachExists=1, @AttachParamsCheck=1, @AttachCheck=1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF @KeyID IS NULL SET @KeyID = 0
IF @KeyID = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

SELECT @Company=Co, @InvoiceDate=InvDate FROM APHB WHERE KeyID=@KeyID

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @InvoiceDate IS NULL
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @Module IS NULL SET @Module = ''
IF  Len(RTrim(@Module)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @FormName IS NULL SET @FormName = ''
IF  Len(RTrim(@FormName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @ImageFileName IS NULL SET @ImageFileName = ''
IF  Len(RTrim(@ImageFileName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @UserAccount IS NULL SET @UserAccount = ''
IF  Len(RTrim(@UserAccount)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

SET @AttachParamsCheck = 0

----------------------------------------------
-- Set Attachment Variables
----------------------------------------------

SELECT	@adddate = GETDATE()
		,@tablename = 'APHB'
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@attachmentTypeID = 4
		,@IsEmail = 'N'

SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
		,@ImageFilePath = [dbo].[mfnDMAttachmentPath] (@Company, @Module, @FormName, @InvoiceDate)
		,@ImageFullFilePath = @ImageFilePath + '\' + @ImageFileName

SELECT @keyfield = 'KeyID=' + CAST(@KeyID as varchar(max))

-- Check for existing attachment
DECLARE @docNameToCheck varchar(512)
DECLARE @docNameCount int
DECLARE @errorMessage varchar(255)

SET @docNameToCheck = @ImageFullFilePath

EXECUTE [dbo].[vspHQATDoesDocNameExist] 
   @docNameToCheck
  ,@docNameCount OUTPUT
  ,@errorMessage OUTPUT

SELECT @docNameCount

IF @docNameCount > 0
BEGIN
	-- Attachment document exists
	 SELECT @rcode=1
	 GOTO ExitProc
END
ELSE
BEGIN
	-- Attachment document doesn't exist
	 SELECT @AttachExists=0
END

----------------------------
-- Adding Attachment Record
----------------------------

BEGIN TRY
BEGIN TRANSACTION Trans_addAttachment

EXECUTE @rcode = [dbo].[vspHQATInsert] 
   @Company
  ,@FormName
  ,@keyfield
  ,@Description
  ,@UserAccount
  ,@adddate
  ,@ImageFullFilePath
  ,@tablename
  ,@ImageFileName
  ,@attid OUTPUT
  ,@uniqueattchid OUTPUT
  ,@docattchyn
  ,@createAsStandAloneAttachment
  ,@attachmentTypeID
  ,@IsEmail
  ,@msg OUTPUT

SET @AttachCheck = @rcode

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAttachment
	    SELECT @rcode=1
	    GOTO ExitProc
	END

COMMIT TRANSACTION Trans_addAttachment
SELECT @rcode=0, @AttachCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAttachment
	SELECT @rcode=1
END CATCH

ExitProc:

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0))
BEGIN
	SELECT @RetVal=0  -- Attachment record created successfully.
	GOTO Final
END
IF (@AttachExists=1)
BEGIN
	SELECT @RetVal=1  -- No record created.  Attachment document already exists.
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=2  -- No record created.  Missing attachment parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1))
BEGIN
	SELECT @RetVal=3  -- No record created.  Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END


Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO