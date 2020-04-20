SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIAddUnmatchedItem]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIAddUnmatchedItem]
GO

-- **************************************************************
--  PURPOSE: Adds new APUI record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    11/29/2014  Created stored procedure
--    11/29/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIAddUnmatchedItem]
	@Company [dbo].[bCompany] = NULL
	,@VendorGroup [dbo].[bGroup] = NULL
	,@Vendor [dbo].[bVendor] = NULL
	,@APRef varchar(15) = NULL
	,@Description [dbo].[bDesc] = NULL
	,@InvDate [dbo].[bDate] = NULL
	,@InvTotal [dbo].[bDollar] = [0]
	,@udFreightCost [dbo].[bDollar] = [0]
	,@KeyID bigint OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @UIMonth smalldatetime, @UISeq int, @HeaderParamsCheck bit, @HeaderCheck bit

SELECT @rcode = -1, @RetVal = -1, @HeaderParamsCheck=1, @HeaderCheck=1

----------------------------
-- Check Header Parameters
----------------------------

IF @Company IS NULL SET @Company = 0
IF @Company = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @VendorGroup IS NULL SET @VendorGroup = 0
IF @VendorGroup = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @Vendor IS NULL SET @Vendor = 0
IF @Vendor = 0
    BEGIN
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @APRef IS NULL SET @APRef = ''
IF  Len(RTrim(@APRef)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

IF @InvTotal IS NULL SET @InvTotal = 0
IF  @InvTotal = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
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

	BEGIN TRANSACTION Trans_addAPUIUnmatchedItem

	EXECUTE @rcode = [dbo].[mckspAPUIAdd] @Company, @VendorGroup, @Vendor, @APRef,
		@Description, @InvDate, @InvTotal, @udFreightCost, @KeyID OUTPUT, @UIMonth OUTPUT, @UISeq OUTPUT

	-- Update header to signify it has been processed by this transaction
	UPDATE bAPUI SET udAPBatchProcessedYN = 'Y' WHERE KeyID = @KeyID

	SET @HeaderCheck = @rcode


	IF @rcode<>0
	BEGIN
	    ROLLBACK TRANSACTION Trans_addAPUIUnmatchedItem
	END

	COMMIT TRANSACTION Trans_addAPUIUnmatchedItem
	    SELECT @rcode=0, @HeaderCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUIUnmatchedItem
	SELECT @rcode=1
END CATCH


ExitProc:

IF ((@HeaderParamsCheck=0) AND (@HeaderCheck=0))
BEGIN
	SELECT @RetVal=0  -- Unmatched Header and Attachment records created successfully.
	GOTO Final
END
IF ((@HeaderParamsCheck=1))
BEGIN
	SELECT @RetVal=1 -- No records created.  Missing header parameters.
	SELECT @rcode=1
	GOTO Final
END
IF ((@HeaderParamsCheck=0) AND (@HeaderCheck=1))
BEGIN
	SELECT @RetVal=2 -- Error creating header record.
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO