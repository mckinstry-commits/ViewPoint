SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIAddUnmatchedItemWithFile]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIAddUnmatchedItemWithFile]
GO

-- **************************************************************
--  PURPOSE: Adds new APUI & Attachment records
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    11/20/2014  Created stored procedure
--    11/20/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIAddUnmatchedItemWithFile]
	@Company [dbo].[bCompany] = NULL
	,@VendorGroup [dbo].[bGroup] = NULL
	,@Vendor [dbo].[bVendor] = NULL
	,@APRef varchar(15) = NULL
	,@Description [dbo].[bDesc] = NULL
	,@InvDate [dbo].[bDate] = NULL
	,@InvTotal [dbo].[bDollar] = [0]
	,@udFreightCost [dbo].[bDollar] = [0]
	,@Module varchar(30)
	,@FormName varchar(30)
	,@ImageFileName nvarchar(512) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@KeyID bigint OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @UIMonth smalldatetime, @UISeq int, 
	@AttachExists bit, @AttachParamsCheck bit, @AttachCheck bit, @HeaderParamsCheck bit, @HeaderCheck bit


-- Attachment variables
DECLARE @keyfield varchar(500), @adddate [dbo].[bDate]
	,@tablename varchar(128), @attid int, @uniqueattchid uniqueidentifier, @docattchyn char(1), 
	@createAsStandAloneAttachment [dbo].[bYN], @attachmentTypeID int, @IsEmail [dbo].[bYN], @msg varchar(100), 
	@ImageFilePath nvarchar(512), @ImageFullFilePath nvarchar(max)

SELECT @rcode = -1, @RetVal = -1, 
	@AttachExists=1, @AttachParamsCheck=1, @AttachCheck=1, @HeaderParamsCheck=1, @HeaderCheck=1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF @ImageFileName IS NULL SET @ImageFileName = ''
IF  Len(RTrim(@ImageFileName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @Module IS NULL SET @Module = ''
IF  Len(RTrim(@Module)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @FormName IS NULL SET @FormName = ''
IF  Len(RTrim(@FormName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @UserAccount IS NULL SET @UserAccount = ''
IF  Len(RTrim(@UserAccount)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO Attachment
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

IF @APRef IS NULL SET @APRef = ''
IF  Len(RTrim(@APRef)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @InvTotal IS NULL SET @InvTotal = 0
IF  @InvTotal = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO Attachment
    END

IF @InvDate IS NULL
BEGIN
	SELECT @InvDate = GetDate()
END

IF @udFreightCost IS NULL SET @udFreightCost = 0

SET @HeaderParamsCheck = 0

----------------------------
-- Adding Header Record
----------------------------

BEGIN TRY

	BEGIN TRANSACTION Trans_addAPUIUnmatched

	EXECUTE @rcode = [dbo].[mckspAPUIAddUnmatchedItem] @Company, @VendorGroup, @Vendor, @APRef, @Description, @InvDate, 
				@InvTotal, @udFreightCost, @KeyID OUTPUT, @RetVal OUTPUT

	-- Update header to signify it has been processed by this transaction
	UPDATE bAPUI SET udAPBatchProcessedYN = 'Y' WHERE KeyID = @KeyID

	SET @HeaderCheck = @rcode

	SELECT @keyfield = 'KeyID=' + CAST(@KeyID as varchar(max))

	IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUIUnmatched
	END

	COMMIT TRANSACTION Trans_addAPUIUnmatched
	    SELECT @rcode=0, @HeaderCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUIUnmatched
	SELECT @rcode=1
END CATCH

Attachment:

BEGIN TRY

	BEGIN TRANSACTION Trans_addAttach

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
		BEGIN -- Error in header record, so create standalone attachment
			SELECT	@createAsStandAloneAttachment = 'Y'
					,@keyfield = NULL
					,@tablename = NULL
					,@Standalone = 1
		END

	SELECT	@ImageFileName = (CASE WHEN (CHARINDEX('\', @ImageFileName) > 0) THEN RIGHT(@ImageFileName, CHARINDEX('\', REVERSE(@ImageFileName)) - 1) ELSE @ImageFileName END)
			,@Company = (CASE WHEN (@Standalone = 1) THEN 0 ELSE @Company END)
			,@ImageFilePath = [dbo].[mfnDMAttachmentPath] (@Company, @Module, @FormName, @InvDate)
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
					UPDATE [dbo].[bAPUI] SET UniqueAttchID = @AttachmentID WHERE KeyID = @KeyID
					SELECT @AttachCheck=0
				END
		END
	ELSE
		BEGIN
			-- Attachment document doesn't exist
			 SELECT @AttachExists=0
		END

	----------------------------
	-- Adding Attachment Record
	----------------------------
	IF (@AttachExists=0)
		BEGIN
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
		END

	IF @rcode<>0
		BEGIN
			ROLLBACK TRANSACTION Trans_addAttach
			SELECT @rcode=1
			GOTO ExitProc
		END

	COMMIT TRANSACTION Trans_addAttach
			SELECT @rcode=0, @AttachCheck=0

END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAttach
	  SELECT @rcode=1
END CATCH


ExitProc:

IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@AttachExists=0) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=0  -- Unmatched Header and Attachment records created successfully.
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@AttachExists=1) AND (@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=1  -- Unmatched Header and Attachment records created successfully.  Attachment already exists.
	SELECT @rcode=0
	GOTO Final
END
IF ((@AttachParamsCheck=1))
BEGIN
	SELECT @RetVal=2 -- No records created.  Missing attachment parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@AttachExists=0) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=3 -- Standalone attachment created.  Missing header parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@AttachParamsCheck=0) AND (@AttachCheck=0) AND (@AttachExists=1) AND (@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=4 -- No records created.  Missing header parameters.  Attachment exists.
	SELECT @rcode=1
	GOTO Final
END
IF ((@HeaderParamsCheck=0) AND (@HeaderCheck=1) AND (@AttachCheck=0) AND (@AttachExists=0))
BEGIN
	SELECT @RetVal=5 -- Standalone attachment created.  Error creating header record.
	SELECT @rcode=1
	GOTO Final
END
IF (((@HeaderParamsCheck=0) AND (@HeaderCheck=0)) AND ((@AttachParamsCheck=0) AND (@AttachExists=0) AND (@AttachCheck=1)))
BEGIN
	SELECT @RetVal=6  -- Header record created.  Error creating attachment record.
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO