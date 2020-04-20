SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
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
	,@VendorGroup [dbo].[bGroup] = NULL
	,@Vendor [dbo].[bVendor] = NULL
	,@CollectedInvoiceNumber varchar(15) = NULL
	,@Description [dbo].[bDesc] = NULL
	,@CollectedInvoiceDate [dbo].[bDate] = NULL
	,@CollectedInvoiceAmount [dbo].[bDollar] = [0]
	,@CollectedTaxAmount [dbo].[bDollar] = [0]
	,@CollectedShippingAmount [dbo].[bDollar] = [0]
	,@Module varchar(30)
	,@FormName varchar(30)
	,@ImageFilePath nvarchar(512) = NULL
	,@ImageFileName nvarchar(512) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @KeyID bigint, @UIMonth smalldatetime, @UISeq int,
@AttachParamsCheck bit, @AttachCheck bit, @HeaderParamsCheck bit, @HeaderCheck bit, @FooterParamsCheck bit, @FooterCheck bit


-- Attachment variables
DECLARE @keyfield varchar(500), @adddate [dbo].[bDate]
	,@tablename varchar(128), @attid int, @uniqueattchid uniqueidentifier, @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @attachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), @ImageFullFilePath nvarchar(max)

SELECT @rcode = -1, @RetVal = -1, 
	@AttachParamsCheck=1, @AttachCheck=1, @HeaderParamsCheck=1, @HeaderCheck=1, @FooterParamsCheck=1, @FooterCheck=1

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

IF @ImageFilePath IS NULL SET @ImageFilePath = ''
IF  Len(RTrim(@ImageFilePath)) = 0
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
-- Check Header Parameters
----------------------------

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @VendorGroup IS NULL SET @VendorGroup = 0
IF @VendorGroup = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @Vendor IS NULL SET @Vendor = 0
IF @Vendor = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @CollectedInvoiceNumber IS NULL SET @CollectedInvoiceNumber = '0'
IF @CollectedInvoiceNumber = '0'
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @CollectedInvoiceDate IS NULL
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @CollectedInvoiceAmount IS NULL SET @CollectedInvoiceAmount = 0

IF @CollectedShippingAmount IS NULL SET @CollectedShippingAmount = 0

SET @HeaderParamsCheck = 0

----------------------------
-- Check Footer Parameters
----------------------------

IF @RecordType IS NULL SET @RecordType = ''
IF  Len(RTrim(@RecordType)) = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @CollectedTaxAmount IS NULL SET @CollectedTaxAmount = 0

SET @FooterParamsCheck = 0

----------------------------
-- Adding Header Record
----------------------------

BEGIN TRY
BEGIN TRANSACTION Trans_addAPUI

EXECUTE @rcode = [dbo].[mckspAPUIAdd] @Company, @VendorGroup, @Vendor, @CollectedInvoiceNumber,
	@Description, @CollectedInvoiceDate, @CollectedInvoiceAmount, @CollectedShippingAmount, @KeyID OUTPUT, @UIMonth OUTPUT, @UISeq OUTPUT

SET @HeaderCheck = @rcode

SELECT @keyfield = 'KeyID=' + CAST(@KeyID as varchar(max))

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUI
	    GOTO Attachment
	END

----------------------------
-- Adding Footer Records
----------------------------

EXECUTE @rcode = [dbo].[mckspAPULAdd] @RecordType, @CollectedInvoiceNumber, @Company, @UIMonth, @UISeq, @VendorGroup, @CollectedInvoiceAmount, @CollectedTaxAmount

SET @FooterCheck = @rcode

IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUI
	    GOTO Attachment
	END

COMMIT TRANSACTION Trans_addAPUI
	    SELECT @rcode=0, @HeaderCheck=0, @FooterCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUI
	  SELECT @rcode=1
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
		,@tablename = 'APUI'
		,@docattchyn = 'N'
		,@createAsStandAloneAttachment = 'N'
		,@attachmentTypeID = 4
		,@IsEmail = 'N'
		,@Standalone = 0

IF @rcode<>0
	BEGIN -- Error in header/footer record, so create standalone attachment
	    SELECT	@createAsStandAloneAttachment = 'Y'
				,@keyfield = NULL
				,@tablename = NULL
				,@Standalone = 1
	END

SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
		,@ImageFilePath = [dbo].[fnMckCreateImageFolderDestination] (@Company, @Module, @FormName, @ImageFilePath, @CollectedInvoiceDate, @Standalone)
		,@ImageFullFilePath = @ImageFilePath + '\' + @ImageFileName

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

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=0))
BEGIN
	SELECT @RetVal=0  -- Header, Footer and Attachment records created successfully.
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=1 -- Standalone attachment created.  Missing header parameters.
	SELECT @rcode=1
	GOTO Final
END

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@FooterParamsCheck=1))
BEGIN
	SELECT @RetVal=2 -- Standalone attachment created.  Missing footer parameters.
	SELECT @rcode=1
	GOTO Final
END

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=1))
BEGIN
	SELECT @RetVal=3 -- Standalone attachment created.  Error creating header record.
	SELECT @rcode=1
	GOTO Final
END

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=1))
BEGIN
	SELECT @RetVal=4  -- Standalone attachment created.  Error creating footer record.
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachParamsCheck=1)
BEGIN
	SELECT @RetVal=5  -- No records created.  Missing attachment parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND ((@HeaderParamsCheck=1) OR (@HeaderCheck=1) OR (@FooterParamsCheck=1) OR (@FooterCheck=1)))
BEGIN
	SELECT @RetVal=6  -- No records created.  Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0) AND (@FooterParamsCheck=0) AND (@FooterCheck=0))
BEGIN
	SELECT @RetVal=7  -- Header and Footer records created successfully. Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO
