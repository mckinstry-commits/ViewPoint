USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIDelete]
GO

-- **************************************************************
--  PURPOSE: Deletes APUI record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/31/2015  Created stored procedure
--    03/31/2015  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIDelete]
	@KeyID bigint = NULL
	,@Message varchar(512) OUTPUT
	,@RetVal int OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @ParamsCheck int, @TransCheck int

SELECT @rcode = -1, @RetVal = -1, @ParamsCheck = 1, @TransCheck = 1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF @KeyID IS NULL SET @KeyID = 0
IF @KeyID = 0
    BEGIN
	 SET @rcode=1
	 GOTO ExitProc
    END

SET @ParamsCheck = 0

BEGIN TRY
BEGIN TRANSACTION Trans_delAPUI

DELETE FROM bAPUI WHERE KeyID = @KeyID

COMMIT TRANSACTION Trans_delAPUI
SELECT @rcode=0, @TransCheck=0

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_delAPUI
	SELECT @rcode=1, @TransCheck=1
END CATCH

ExitProc:

SET @Message = 'Procedure executed.'

IF ((@ParamsCheck=0) AND (@TransCheck=0))
BEGIN
	SELECT @RetVal=0 
	SELECT @Message = 'APUI record deleted successfully.'
	SELECT @rcode=0
	GOTO Final
END
IF (@ParamsCheck=1)
BEGIN
	SELECT @RetVal=1 
	SELECT @Message = 'No records deleted.  Missing parameters.'
	SELECT @rcode=1
	GOTO Final
END
IF ((@ParamsCheck=0) AND (@TransCheck=1))
BEGIN
	SELECT @RetVal=2  
	SELECT @Message = 'No records deleted.  Error deleting APUI record.'
	SELECT @rcode=1
	GOTO Final
END

Final:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO