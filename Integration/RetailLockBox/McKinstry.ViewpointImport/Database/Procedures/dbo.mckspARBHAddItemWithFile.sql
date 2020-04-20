USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspARBHAddItemWithFile]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspARBHAddItemWithFile]
GO

-- **************************************************************
--  PURPOSE: Adds new HQBC, ARBH & Attachment records
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    05/28/2014  Created stored procedure
--    05/28/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspARBHAddItemWithFile]
	@Company [dbo].[bCompany] = NULL
	,@TransactionDate datetime = NULL
	,@Customer [dbo].[bCustomer] = [0]
	,@CustomerGroup [dbo].[bGroup] = [0]
	,@CheckAmount [dbo].[bDollar] = [0]
	,@Module varchar(30) = NULL
	,@FormName varchar(30) = NULL
	,@InvoiceNumber char(10) = NULL
	,@CheckNumber char(10) = NULL
	,@CheckDate smalldatetime = NULL
	,@ImageFileName nvarchar(512) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@BatchId int OUTPUT
	,@HeaderKeyID bigint OUTPUT
	,@AttachmentID int OUTPUT
	,@Message varchar(512) OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @UIMonth smalldatetime, @TableName varchar(128),
@AttachParamsCheck bit, @AttachCheck bit, @BatchParamsCheck bit, @BatchCheck bit, @BatchCreated bit, @HeaderParamsCheck bit, @HeaderCheck bit

SELECT @UIMonth = [dbo].[vfFirstDayOfMonth] (@TransactionDate), @TableName = 'ARBH'

-- Attachment variables
DECLARE @KeyField varchar(500), @AddDate [dbo].[bDate]
	,@attid int, @uniqueattchid uniqueidentifier, @Description [dbo].[bDesc], @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @AttachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), 
	@ImageFilePath nvarchar(512), @ImageFullFilePath nvarchar(max)

-- Batch variables
DECLARE @DepositNumber [dbo].[bCMRef], @Notes varchar(max)

SELECT @Notes = 'Invoice: ' + CAST(@InvoiceNumber as varchar(max))

-- Header variables
-- Deposit number is (MMDDYYCC01)
SET @DepositNumber = (SELECT [dbo].[fnMckARDepositNumber](@Company, @TransactionDate, 'LB'))

SELECT @rcode = -1, @RetVal = -1, 
	@AttachParamsCheck=1, @AttachCheck=1, @BatchParamsCheck=1, @BatchCheck=1, @BatchCreated=1, @HeaderParamsCheck=1, @HeaderCheck=1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------
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

----------------------------
-- Check Batch Parameters
----------------------------

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

SET @BatchParamsCheck = 0

----------------------------
-- Check Header Parameters
----------------------------


SET @HeaderParamsCheck = 0

----------------------------
-- Adding Batch Record
----------------------------

BEGIN TRY

BEGIN TRANSACTION Trans_addARBHMain

-- Check for existing batch for company, month and deposit number
SET @BatchId = (SELECT MAX(BatchId) FROM ARBH WHERE Co = @Company AND Mth = @UIMonth AND CMDeposit = (SELECT [dbo].[fnMckFormatWithLeading](@DepositNumber, ' ', 10)))
-- If batch doesn't exist, create new batch
IF (@BatchId IS NULL)
BEGIN
	EXECUTE @rcode = [dbo].[mckspHQBCAdd] @Company, @UIMonth, @UserAccount, @Notes, @BatchId OUTPUT
	SELECT @BatchCreated = 0
	SET @BatchCheck = @rcode
END
ELSE
BEGIN
	SET @BatchCheck = 0
END

----------------------------
-- Adding Header Record
----------------------------

EXECUTE @rcode = [dbo].[mckspARBHAdd] @Company, @UIMonth, @BatchId, @CustomerGroup, @Customer, @CheckNumber, 
	@Description, @TransactionDate, @CheckDate, @CheckAmount, @DepositNumber, @Notes, @HeaderKeyID OUTPUT

SET @HeaderCheck = @rcode

COMMIT TRANSACTION Trans_addARBHMain
	    SELECT @rcode=0, @BatchCheck=0, @HeaderCheck=0

END TRY

BEGIN CATCH
	SELECT @rcode=1
	ROLLBACK TRANSACTION Trans_addARBHMain
END CATCH

----------------------------
-- Adding Attachment Record
----------------------------
Attachment:

----------------------------------------------
-- Set Attachment Variables
----------------------------------------------

DECLARE @Standalone bit

SELECT	@AddDate = GETDATE()
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@AttachmentTypeID = 50058 -- 'AR Receipt'
		,@IsEmail = 'N'
		,@Standalone = 0
		,@KeyField = 'KeyID=' + CAST(@HeaderKeyID as varchar(max))

IF @rcode<>0
BEGIN -- Error in header/footer record, so create standalone attachment
	SELECT	@createAsStandAloneAttachment = 'Y'
			,@KeyField = NULL
			,@TableName = NULL
			,@Standalone = 1
END

SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
		,@ImageFilePath = [dbo].[mfnDMAttachmentPath] (@Company, @Module, @FormName, @TransactionDate)
		,@ImageFullFilePath = @ImageFilePath + '\' + @ImageFileName

-- Create and assign attachment variables
DECLARE @FilePathPart varchar(512), @FileSuffix nvarchar(100), @AttachCount int

SET @FilePathPart = LEFT(@ImageFullFilePath, CHARINDEX('.', @ImageFullFilePath) - 1)
SET @AttachCount = (SELECT COUNT (*) FROM HQAT WHERE DocName LIKE @FilePathPart + '%')
SELECT @FileSuffix = (CASE WHEN @AttachCount > 0 THEN '_' + CAST((@AttachCount + 1) as varchar(100)) + '.pdf' ELSE '.pdf' END)
SET @ImageFullFilePath = @FilePathPart + @FileSuffix

BEGIN TRY
BEGIN TRANSACTION Trans_addAttachment

EXECUTE @rcode = [dbo].[vspHQATInsert] 
   @Company
  ,@FormName
  ,@KeyField
  ,@Description
  ,@UserAccount
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

SELECT @AttachmentID = @attid
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

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=0
	SELECT @Message = 'Batch, Header and Attachment records created successfully.'
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=1
	SELECT @Message = 'Header and Attachment records created successfully.'
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=1))
BEGIN
	SELECT @RetVal=2  
	SELECT @Message = 'Standalone attachment created.  Missing batch parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=3  
	SELECT @Message = 'Standalone attachment created.  Missing header parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=1))
BEGIN
	SELECT @RetVal=4 
	SELECT @Message = 'Standalone attachment created.  Error creating batch record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=1))
BEGIN
	SELECT @RetVal=5 
	SELECT @Message = 'Standalone attachment created.  Error creating header record.'
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=6
	SELECT @Message = 'No records created.  Missing attachment parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND ((@BatchParamsCheck=1) OR (@BatchCheck=1) OR (@HeaderParamsCheck=1) OR (@HeaderCheck=1)))
BEGIN
	SELECT @RetVal=7
	SELECT @Message = 'No records created.  Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=8
	SELECT @Message = 'Header record created successfully. Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=9 
	SELECT @Message = 'Batch and Header records created successfully. Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO