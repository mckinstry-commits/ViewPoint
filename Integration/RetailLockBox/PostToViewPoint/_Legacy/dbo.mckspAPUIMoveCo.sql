SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIMoveCo]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIMoveCo]
GO

-- **************************************************************
--  PURPOSE: Moves AP Header records between companies
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    11/20/2014  Created stored procedure
--    11/20/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIMoveCo]
	@Module varchar(30) = NULL
	,@FormName varchar(30) = NULL
	,@UserAccount nvarchar(200) = NULL
	,@Success varchar(max) OUTPUT
	,@FileCopy varchar(max) OUTPUT
	,@Failure varchar(max) OUTPUT
	,@RetVal int OUTPUT
AS

SET NOCOUNT ON

-- Return value variables
DECLARE @rcode int, @NewKeyID bigint, @ParamsCheck int
SELECT @rcode = -1, @RetVal = -1, @ParamsCheck=1

----------------------------------------------
-- Validate Inputs
----------------------------------------------
IF @UserAccount IS NULL SET @UserAccount = ''
IF  Len(RTrim(@UserAccount)) = 0
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
	 GOTO ExitProc
    END

IF @FormName IS NULL SET @FormName = ''
IF  Len(RTrim(@FormName)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

SET @ParamsCheck = 0

DECLARE @FileMoveTable table
(
	FileMoveID int identity(1,1),
	OldAttachFile varchar(512),
	NewAttachFile varchar(512)
)

DECLARE @ProcessTable table
(
	ID int identity(1,1),
	APCo [dbo].[bCompany] NULL,
	UIMth [dbo].[bMonth] NULL,
	VendorGroup [dbo].[bGroup] NULL,
	Vendor [dbo].[bVendor] NULL,
	APRef [dbo].[bAPReference] NULL,
	Description [dbo].[bDesc] NULL,
	InvDate [dbo].[bDate] NULL,
	InvTotal [dbo].[bDollar] NULL,
	UniqueAttchID uniqueidentifier NULL,
	FreightCost [dbo].[bDollar] NULL,
    DestAPCo [dbo].[bCompany] NULL,
	KeyID bigint NULL
)

INSERT INTO @ProcessTable(APCo, UIMth, VendorGroup, Vendor, APRef, Description, InvDate, InvTotal, UniqueAttchID, FreightCost, DestAPCo, KeyID)
SELECT APCo, UIMth, VendorGroup, Vendor, APRef, Description, InvDate, InvTotal, UniqueAttchID, udFreightCost, udDestAPCo, KeyID
FROM APUI 
WHERE udDestAPCo > 0 AND (APCo <> udDestAPCo)


DECLARE @RowCount int, @i int
SET @RowCount = (SELECT COUNT(*) FROM @ProcessTable) 
SET @i = 1

WHILE (@i <= @RowCount)
BEGIN
	-- Variables for process table row items
	DECLARE @APCo [dbo].[bCompany], @UIMth [dbo].[bMonth], @VendorGroup [dbo].[bGroup], @Vendor [dbo].[bVendor], @APRef [dbo].[bAPReference],
		@Description [dbo].[bDesc], @InvDate [dbo].[bDate], @InvTotal [dbo].[bDollar], @UniqueAttchID uniqueidentifier, 
		@FreightCost [dbo].[bDollar], @DestAPCo [dbo].[bCompany], @KeyID bigint

	-- Fill values from process table row
	SELECT @APCo=APCo, @UIMth=UIMth, @VendorGroup=VendorGroup, @Vendor=Vendor, @APRef=APRef, @Description=Description, @InvDate=InvDate, 
		@InvTotal=InvTotal, @UniqueAttchID=UniqueAttchID, @FreightCost=FreightCost, @DestAPCo=DestAPCo, @KeyID=KeyID
	FROM @ProcessTable WHERE ID = @i

	IF (@UniqueAttchID IS NULL)
	BEGIN
		SET @Failure = ISNULL(@Failure, '') + @APRef + '|Cannot process item.  Missing attachment.;'
		GOTO SkipItem
	END

	DECLARE @AttachCount int
	SET @AttachCount = (SELECT COUNT(HQAT.OrigFileName) FROM HQAT WHERE HQAT.UniqueAttchID = @UniqueAttchID)
	IF (@AttachCount > 1)
	BEGIN
		SET @Failure = ISNULL(@Failure, '') + @APRef + '|Cannot process item.  Multiple attachments.;'
		GOTO SkipItem
	END


	-- Variables for attachmentfile move operations
	DECLARE @OldAttachFile varchar(512), @NewAttachFile varchar(512), @NewUniqueAttachID uniqueidentifier, 
	@OrigFileName varchar(512)
		
	BEGIN TRY

		BEGIN TRANSACTION Trans_moveAPCo

		SET @OrigFileName = (SELECT HQAT.OrigFileName FROM HQAT WHERE HQAT.UniqueAttchID = @UniqueAttchID)
		-- Add values from existing AP Header record in new AP Header with DestAPCo company
		EXECUTE @rcode = [dbo].[mckspAPUIAddUnmatchedItemWithFile] @DestAPCo, @VendorGroup, @Vendor, @APRef, 
			'*', @InvDate, @InvTotal, @FreightCost, @Module, @FormName, @OrigFileName, @UserAccount, @NewKeyID OUTPUT, @RetVal OUTPUT
		IF (@rcode = 0)
			BEGIN
				-- Delete existing AP Header record KeyID
				DELETE FROM bAPUI WHERE bAPUI.KeyID = @KeyID

				-- Set variables for file move
				SET @OldAttachFile = (SELECT HQAT.DocName FROM HQAT WHERE HQAT.UniqueAttchID = @UniqueAttchID)

				-- Delete the attachment record if not attached to another AP header record
				IF NOT EXISTS(SELECT 1 FROM APUI WHERE UniqueAttchID = @UniqueAttchID)
				BEGIN
					DELETE FROM bHQAT WHERE bHQAT.UniqueAttchID = @UniqueAttchID
				END

				-- Set variables for file move
				SET @NewUniqueAttachID = (SELECT APUI.UniqueAttchID FROM APUI WHERE APUI.KeyID = @NewKeyID)
				SET @NewAttachFile = (SELECT HQAT.DocName FROM HQAT WHERE HQAT.UniqueAttchID = @NewUniqueAttachID)
				-- Add unique file move data into file move table 
				IF NOT EXISTS(SELECT 1 FROM @FileMoveTable WHERE OldAttachFile = @OldAttachFile AND NewAttachFile = @NewAttachFile)
				BEGIN
					INSERT INTO @FileMoveTable(OldAttachFile, NewAttachFile) SELECT @OldAttachFile, @NewAttachFile
				END

				-- Set success output 'soureco|apref|destco;'
				SET @Success = ISNULL(@Success, '') + CAST(@APCo as varchar(100)) + '|' + @APRef + '|' + CAST(@DestAPCo as varchar(100)) + ';'
			END
		IF (@RetVal > 1)
			BEGIN
				-- Set failure output 'apref|errormessage;'
				SET @Failure = ISNULL(@Failure, '') + @APRef + '|[dbo].[mckspAPUIAddUnmatchedItemWithFile] Return Error Code: ' + @RetVal + ';'
			END

		COMMIT TRANSACTION Trans_moveAPCo

	END TRY

	BEGIN CATCH
		-- Set failure output 'apref|errormessage;'
		SET @Failure = ISNULL(@Failure, '') + @APRef + '|' +  ERROR_MESSAGE() + ';'
		ROLLBACK TRANSACTION Trans_moveAPCo
	END CATCH

	SkipItem:

	SET @i = @i  + 1
END

SET @RowCount = (SELECT COUNT(*) FROM @FileMoveTable) 
SET @i = 1
WHILE (@i <= @RowCount)
BEGIN
	DECLARE @OldFile varchar(512), @NewFile varchar(512)

	SELECT @OldFile=OldAttachFile, @NewFile=NewAttachFile
	FROM @FileMoveTable WHERE FileMoveID = @i

    -- Set file copy output 'soureco|apref|destco;'
	SET @FileCopy = ISNULL(@FileCopy, '') + @OldFile + '|' + @NewFile + ';'
	SET @i = @i  + 1
END

-- Trim ending delimeters from output
SET @Success = (CASE WHEN (LEN(@Success) > 0) THEN LEFT(@Success, LEN(@Success) - 1) ELSE NULL END)
SET @FileCopy = (CASE WHEN (LEN(@FileCopy) > 0) THEN LEFT(@FileCopy, LEN(@FileCopy) - 1) ELSE NULL END)
SET @Failure = (CASE WHEN (LEN(@Failure) > 0) THEN LEFT(@Failure, LEN(@Failure) - 1) ELSE NULL END)

ExitProc:

IF (@ParamsCheck=1)
BEGIN
	SELECT @RetVal=1  -- Batch not processed.  Missing parameters.
	SELECT @rcode=1
	GOTO Final
END

SELECT @RetVal=0, @rcode=0  -- Batch processed successfully.

Final:
RETURN(@rcode)


SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO
