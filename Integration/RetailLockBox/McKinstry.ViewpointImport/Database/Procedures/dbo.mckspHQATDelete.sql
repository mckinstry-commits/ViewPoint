USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspHQATDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspHQATDelete]
GO

-- **************************************************************
--  PURPOSE: Deletes Attachment record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/31/2015  Created stored procedure
--    03/31/2015  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspHQATDelete]
	@AttachmentID int = NULL
	,@Message varchar(512) OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @ParamsCheck int, @AttachCheck int, @ProcessCheck int

SELECT @rcode = -1, @RetVal = -1, @ParamsCheck = 1, @AttachCheck = 1, @ProcessCheck = 1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF @AttachmentID IS NULL SET @AttachmentID = 0
IF @AttachmentID = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

SET @ParamsCheck = 0

IF NOT EXISTS(SELECT 1 FROM HQAT WITH (NOLOCK) WHERE AttachmentID = @AttachmentID)
    BEGIN
	 SET @rcode=0
	 GOTO ExitProc
    END

SET @AttachCheck = 0

BEGIN TRY
BEGIN TRANSACTION Trans_delAttachment

DELETE FROM bHQAT WHERE AttachmentID = @AttachmentID

COMMIT TRANSACTION Trans_delAttachment
SELECT @rcode=0, @ProcessCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_delAttachment
	SELECT @rcode=1, @ProcessCheck=1
END CATCH

ExitProc:

SET @Message = 'Procedure executed.'

IF ((@ParamsCheck=0) AND (@AttachCheck=0) AND (@ProcessCheck=0))
BEGIN
	SELECT @RetVal=0 
	SELECT @Message = 'Attachment record deleted successfully.'
	SELECT @rcode=0
	GOTO Final
END
IF (@ParamsCheck=1)
BEGIN
	SELECT @RetVal=1 
	SELECT @Message = 'No records deleted.  Missing attachment parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF (@AttachCheck=1)
BEGIN
	SELECT @RetVal=2 
	SELECT @Message = 'No records deleted.  Attachment already deleted.'
	SELECT @rcode=0
	GOTO Final
END
IF ((@ParamsCheck=0) AND (@AttachCheck=0) AND (@ProcessCheck=1))
BEGIN
	SELECT @RetVal=3  
	SELECT @Message = 'No records deleted.  Error deleting attachment record.'
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO