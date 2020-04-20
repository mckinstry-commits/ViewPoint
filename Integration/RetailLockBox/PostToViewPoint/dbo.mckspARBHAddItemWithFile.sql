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
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @KeyID bigint, @UIMonth smalldatetime, @TableName varchar(128), @AttachExists bit, 
@AttachParamsCheck bit, @AttachCheck bit, @BatchParamsCheck bit, @BatchCheck bit, @BatchCreated bit, @HeaderParamsCheck bit, @HeaderCheck bit

SELECT @UIMonth = [dbo].[vfFirstDayOfMonth] (@TransactionDate), @TableName = 'ARBH'

-- Attachment variables
DECLARE @keyfield varchar(500), @adddate [dbo].[bDate]
	,@attid int, @uniqueattchid uniqueidentifier, @Description [dbo].[bDesc], @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @attachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), 
	@ImageFilePath nvarchar(512), @ImageFullFilePath nvarchar(max)

-- Batch variables
DECLARE @DepositNumber [dbo].[bCMRef], @Notes varchar(max)

SELECT @Notes = 'Invoice: ' + CAST(@InvoiceNumber as varchar(max))

-- Header variables
-- Deposit number is (MMDDYYCC01)
SET @DepositNumber = (SELECT [dbo].[fnMckARDepositNumber](@Company, @TransactionDate, 'LB'))

SELECT @rcode = -1, @RetVal = -1, 
	@AttachExists=1, @AttachParamsCheck=1, @AttachCheck=1, @BatchParamsCheck=1, @BatchCheck=1, @BatchCreated=1, @HeaderParamsCheck=1, @HeaderCheck=1

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
	@Description, @TransactionDate, @CheckDate, @CheckAmount, @DepositNumber, @Notes, @KeyID OUTPUT

SET @HeaderCheck = @rcode

SELECT @keyfield = 'KeyID=' + CAST(@KeyID as varchar(max))

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

SELECT	@adddate = GETDATE()
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@attachmentTypeID = 50058 -- 'AR Receipt'
		,@IsEmail = 'N'
		,@Standalone = 0

IF @rcode<>0
BEGIN -- Error in header/footer record, so create standalone attachment
	SELECT	@createAsStandAloneAttachment = 'Y'
			,@keyfield = NULL
			,@TableName = NULL
			,@Standalone = 1
END

SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
		,@ImageFilePath = [dbo].[mfnDMAttachmentPath] (@Company, @Module, @FormName, @TransactionDate)
		,@ImageFullFilePath = @ImageFilePath + '\' + @ImageFileName

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
	-- Attachment document exists, attach document to existing header record
	 DECLARE @AttachmentID uniqueidentifier
	 SELECT @AttachmentID = UniqueAttchID FROM HQAT WHERE DocName = @docNameToCheck
	 IF @AttachmentID IS NULL
		BEGIN
			SELECT @AttachCheck=1
		END
	 ELSE
		BEGIN
			UPDATE [dbo].[bARBH] SET UniqueAttchID = @AttachmentID WHERE KeyID = @KeyID
			SELECT @AttachCheck=0
		END
	 GOTO ExitProc
END
ELSE
BEGIN
	-- Attachment document doesn't exist
	 SELECT @AttachExists=0
END

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
  ,@TableName
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

IF ((@AttachParamsCheck=0) AND (@AttachExists=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=0  -- Batch, Header and Attachment records created successfully.
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachExists=1) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=1  -- Batch, Header and Attachment records created successfully.  Attachment exists.
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachExists=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=2  -- Header and Attachment records created successfully.
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachExists=1) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=3  -- Header and Attachment records created successfully.  Attachment exists.
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=1))
BEGIN
	SELECT @RetVal=4 -- Standalone attachment created.  Missing batch parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=5 -- Standalone attachment created.  Missing header parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=1))
BEGIN
	SELECT @RetVal=6 -- Standalone attachment created.  Error creating batch record.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=1))
BEGIN
	SELECT @RetVal=7  -- Standalone attachment created.  Error creating header record.
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=8  -- No records created.  Missing attachment parameters.
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachExists=1)
BEGIN
	SELECT @RetVal=9  -- No records created.  Attachment exists.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND ((@BatchParamsCheck=1) OR (@BatchCheck=1) OR (@HeaderParamsCheck=1) OR (@HeaderCheck=1)))
BEGIN
	SELECT @RetVal=10  -- No records created.  Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=11  -- Header record created successfully. Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@BatchParamsCheck=0) AND (@BatchCheck=0) AND (@BatchCreated=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=12  -- Batch and Header records created successfully. Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO