SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIAddItemWithFile]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIAddItemWithFile]
GO

-- **************************************************************
--  PURPOSE: Adds new APUI, APUL & Attachment records
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    04/21/2014  Created stored procedure
--    05/16/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIAddItemWithFile]
	@RecordType nvarchar(30) = NULL
	,@Company [dbo].[bCompany] = NULL
	,@TransactionDate datetime = NULL
	,@Number varchar(30) = NULL
	,@VendorGroup [dbo].[bGroup] = NULL
	,@Vendor [dbo].[bVendor] = NULL
	,@CollectedInvoiceNumber varchar(50) = NULL
	,@Description [dbo].[bDesc] = NULL
	,@CollectedInvoiceDate [dbo].[bDate] = NULL
	,@CollectedInvoiceAmount [dbo].[bDollar] = [0]
	,@CollectedTaxAmount [dbo].[bDollar] = [0]
	,@CollectedShippingAmount [dbo].[bDollar] = [0]
	,@Module varchar(30)
	,@FormName varchar(30)
	,@ImageFileName nvarchar(512) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@UnmatchedCompany [dbo].[bCompany] = NULL
	,@UnmatchedVendorGroup [dbo].[bGroup] = NULL
	,@UnmatchedVendor [dbo].[bVendor] = NULL
	,@AttachmentID int OUTPUT
	,@UniqueAttachmentID uniqueidentifier OUTPUT
	,@AttachmentFilePath varchar(512) OUTPUT
	,@HeaderKeyID bigint OUTPUT
	,@FooterKeyID bigint OUTPUT
	,@Message varchar(512) OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @UIMonth [dbo].[bDate], @UISeq int,
	@AttachParamsCheck bit, @AttachCheck bit, @HeaderParamsCheck bit, @HeaderCheck bit, @FooterParamsCheck bit, @FooterCheck bit,
	@UnmatchedParamsCheck bit, @UnmatchedCheck bit

-- Attachment variables
DECLARE @keyfield varchar(500), @adddate [dbo].[bDate]
	,@tablename varchar(128), @attid int, @uniqueattchid uniqueidentifier, @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @attachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), 
	@ImageFilePath varchar(512), @ImageFullFilePath nvarchar(max)

SELECT @rcode = -1, @RetVal = -1, @HeaderKeyID = -1, @FooterKeyID = -1, @AttachmentID = -1, @UniqueAttachmentID = NULL, @AttachmentFilePath = NULL, @AttachParamsCheck=1, @AttachCheck=1, 
	@HeaderParamsCheck=1, @HeaderCheck=1, @FooterParamsCheck=1, @FooterCheck=1, @UnmatchedParamsCheck=1, @UnmatchedCheck=1

IF @TransactionDate IS NULL SET @TransactionDate = GETDATE()
SELECT @UIMonth = [dbo].[vfFirstDayOfMonth] (@TransactionDate)

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

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

IF @UserAccount IS NULL SET @UserAccount = ''
IF  Len(RTrim(@UserAccount)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

SET @AttachParamsCheck = 0

----------------------------
-- Check Header Parameters
----------------------------

-- If no invoice number, create standalone

IF @CollectedInvoiceNumber IS NULL SET @CollectedInvoiceNumber = ''
IF  Len(RTrim(@CollectedInvoiceNumber)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO Attachment
    END

IF @CollectedInvoiceAmount IS NULL SET @CollectedInvoiceAmount = 0

-- Trim CollectedInvoiceNumber down to 15 characters (APRef is varchar(15))
IF LEN(RTRIM(@CollectedInvoiceNumber)) > 15
BEGIN
	SET @CollectedInvoiceNumber = RIGHT(RTrim(@CollectedInvoiceNumber), 15)
	-- Trim away non alpha-numeric characters from beginning of string
	SET @CollectedInvoiceNumber = (CASE WHEN SUBSTRING(@CollectedInvoiceNumber, 1, 1) NOT LIKE '%[0-9a-zA-Z]%' THEN RIGHT(@CollectedInvoiceNumber, LEN(@CollectedInvoiceNumber) - 1) ELSE @CollectedInvoiceNumber END)
END

IF @CollectedShippingAmount IS NULL SET @CollectedShippingAmount = 0

IF @CollectedInvoiceDate IS NULL
BEGIN
	SET @CollectedInvoiceDate = GetDate()
END

-- Missing company and vendor means unmatched

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SET @rcode=1
	 GOTO Unmatched
    END

IF @VendorGroup IS NULL SET @VendorGroup = 0
IF @VendorGroup = 0
    BEGIN
	 SET @rcode=1
	 GOTO Unmatched
    END

IF @Vendor IS NULL SET @Vendor = 0
IF @Vendor = 0
    BEGIN
	 SET @rcode=1
	 GOTO Unmatched
    END

SET @HeaderParamsCheck = 0

----------------------------
-- Check Footer Parameters
----------------------------

IF @RecordType IS NULL SET @RecordType = ''
IF  Len(RTrim(@RecordType)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO Unmatched
    END

IF @Number IS NULL SET @Number = ''
IF  Len(RTrim(@Number)) = 0
    BEGIN
	 SET @rcode=1
	 GOTO Unmatched
    END

-- If Number includes PO/SC/RI with a dash, take the left sequence
SET	@Number = (CASE WHEN (CHARINDEX('-', @Number ) > 0) THEN LEFT(@Number, CHARINDEX('-', @Number) - 1) ELSE @Number END)

IF @CollectedTaxAmount IS NULL SET @CollectedTaxAmount = 0

SET @FooterParamsCheck = 0

----------------------------
-- Adding Header Record
----------------------------

BEGIN TRY
BEGIN TRANSACTION Trans_addAPUI

EXECUTE @rcode = [dbo].[mckspAPUIAddNew] @Company, @UIMonth, @VendorGroup, @Vendor, @CollectedInvoiceNumber, @Description, @CollectedInvoiceDate, 
	@CollectedInvoiceAmount, @CollectedShippingAmount, @HeaderKeyID OUTPUT, @UISeq OUTPUT

IF @rcode=0
	BEGIN
		-- Update header to signify it has been processed by this transaction
		UPDATE [dbo].[bAPUI] SET udAPBatchProcessedYN = 'Y' WHERE KeyID = @HeaderKeyID
		SET @HeaderCheck=0
	END

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUI
		SELECT @rcode=1, @HeaderCheck=1
	    GOTO Unmatched
	END

----------------------------
-- Adding Footer Records
----------------------------

DECLARE @PayTerms [dbo].[bPayTerms]

EXECUTE @rcode = [dbo].[mckspAPULAdd] @RecordType, @Number, @Company, @UIMonth, @UISeq, @VendorGroup, @Vendor, @CollectedInvoiceAmount, @CollectedTaxAmount, @PayTerms OUTPUT, @FooterKeyID OUTPUT

IF @rcode=0
	BEGIN
		-- Fetch payment terms from footer to update due date in header
		DECLARE @InvoiceDate [dbo].[bDate], @DiscDate [dbo].[bDate], @DueDate [dbo].[bDate], 
			@DiscRate [dbo].[bPct], @PayTermsMsg varchar(60)

		SELECT @InvoiceDate = InvDate from APUI WHERE KeyID = @HeaderKeyID

		EXECUTE [dbo].[bspHQPayTermsDateCalc] @PayTerms, @InvoiceDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @PayTermsMsg OUTPUT

		-- Update header with new due date
		UPDATE [dbo].[bAPUI] SET DueDate = @DueDate WHERE KeyID = @HeaderKeyID
	END

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUI
		SELECT @rcode=1, @FooterCheck=1
	    GOTO Unmatched
	END

COMMIT TRANSACTION Trans_addAPUI
	    SELECT @rcode=0, @HeaderCheck=0, @FooterCheck=0
		GOTO Attachment
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUI
	SELECT @rcode=1, @FooterCheck=1
	GOTO Unmatched
END CATCH

Unmatched:
----------------------------
-- Check Unmatched Header Parameters
----------------------------

IF @UnmatchedCompany IS NULL SET @UnmatchedCompany = 0
IF @UnmatchedCompany = 0
	BEGIN
	 SET @rcode=1
	 GOTO Attachment
    END

IF @UnmatchedVendorGroup IS NULL SET @UnmatchedVendorGroup = 0
IF @UnmatchedVendorGroup = 0
    BEGIN
	 SET @rcode=1
	 GOTO Attachment
    END

IF @UnmatchedVendor IS NULL SET @UnmatchedVendor = 0
IF @UnmatchedVendor = 0
    BEGIN
	 SET @rcode=1
	 GOTO Attachment
    END

SET @UnmatchedParamsCheck = 0

----------------------------
-- Adding Unmatched Header Record
----------------------------
IF @rcode<>0
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION Trans_addAPUIUnmatchedHeader

			EXECUTE @rcode = [dbo].[mckspAPUIAddUnmatchedItemNew] @UnmatchedCompany, @UIMonth, @UnmatchedVendorGroup, @UnmatchedVendor, @CollectedInvoiceNumber, '*', @CollectedInvoiceDate, 
				@CollectedInvoiceAmount, @CollectedShippingAmount, @HeaderKeyID OUTPUT, @RetVal OUTPUT

			IF @rcode<>0
				BEGIN
					ROLLBACK TRANSACTION Trans_addAPUIUnmatchedHeader
					SELECT @rcode=1, @UnmatchedCheck=1
					GOTO Attachment
				END

			COMMIT TRANSACTION Trans_addAPUIUnmatchedHeader
					SELECT @rcode=0, @UnmatchedCheck=0, @Company=@UnmatchedCompany
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION Trans_addAPUIUnmatchedHeader
				SELECT @rcode=1, @UnmatchedCheck=1
		END CATCH
	END

----------------------------
-- Adding Attachment Record
----------------------------
Attachment:

----------------------------------------------
-- Set Attachment Variables
----------------------------------------------

DECLARE @Standalone bit

SELECT	@adddate = GETDATE()
		,@tablename = 'APUI'
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@attachmentTypeID = 4
		,@IsEmail = 'N'
		,@Standalone = 0
		,@keyfield = 'KeyID=' + CAST(@HeaderKeyID as varchar(max))

IF @rcode<>0
	BEGIN -- Error in header/footer record, so create standalone attachment
	    SELECT	@createAsStandAloneAttachment = 'Y'
				,@keyfield = NULL
				,@tablename = NULL
				,@Standalone = 1
				,@Company = 0
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

  SELECT @UniqueAttachmentID = @uniqueattchid, @AttachmentID = @attid
  SET @AttachmentFilePath = (CASE WHEN @AttachmentID > 0 THEN @ImageFullFilePath ELSE NULL END)

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

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=0))
BEGIN
	SELECT @RetVal=0 
	SELECT @Message = 'Header, Footer and Attachment records created successfully.'
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=0) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=1
	SELECT @Message = 'Unmatched header and attachment records created.  Missing header parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=1))
BEGIN
	SELECT @RetVal=2
	SELECT @Message = 'Unmatched header and attachment records created.  Error creating header record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=0) AND (@FooterParamsCheck=1))
BEGIN
	SELECT @RetVal=3
	SELECT @Message =  'Unmatched header and attachment records created.  Missing footer parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=1))
BEGIN
	SELECT @RetVal=4
	SELECT @Message =  'Unmatched header and attachment records created.  Error creating footer record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=1))
BEGIN
	SELECT @RetVal=5
	SELECT @Message =  'Standalone attachment created.  Missing unmatched header parameters.'
	SELECT @rcode=1
	GOTO Final
END 
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=1))
BEGIN
	SELECT @RetVal=6
	SELECT @Message =  'Standalone attachment created.  Error creating unmatched header record.'
	SELECT @rcode=1
	GOTO Final
END 
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=7  
	SELECT @Message =  'No records created.  Missing attachment parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@UnmatchedCheck=1))
BEGIN
	SELECT @RetVal=8  
	SELECT @Message =  'No records created.  Error creating unmatched header record.  Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=0))
BEGIN
	SELECT @RetVal=9  
	SELECT @Message =  'Header and Footer records created successfully. Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@UnmatchedParamsCheck=0) AND (@UnmatchedCheck=0))
BEGIN
	SELECT @RetVal=10  
	SELECT @Message =  'Unmatched header record created successfully. Error creating attachment record.'
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO