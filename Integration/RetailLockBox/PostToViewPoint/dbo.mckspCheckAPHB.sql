SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspCheckAPHB]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspCheckAPHB]
GO

-- **************************************************************
--  PURPOSE: Checks for existence of APHB records
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    06/20/2014  Created stored procedure
--    06/20/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspCheckAPHB]
	@ExpenseID varchar(13) = NULL
	,@KeyID bigint OUTPUT

AS

SET NOCOUNT ON

-- Common variables
DECLARE @rcode int, @ParamsCheck bit, @APHBCheck bit

SELECT @rcode = -1, @ParamsCheck=1, @APHBCheck=1

----------------------------------------------
-- Validate Inputs
----------------------------------------------

IF @ExpenseID IS NULL SET @ExpenseID = ''
IF  Len(RTrim(@ExpenseID)) = 0
    BEGIN
	-- Invalid parameter passed
	 SELECT @rcode=1
	 GOTO ExitProc
    END

SET @ParamsCheck = 0

----------------------------------------------
-- Check for APHB record
----------------------------------------------
BEGIN TRY

DECLARE @APRef varchar(15)

SET @APRef = 'EW' + @ExpenseID

SET @KeyID = (SELECT MAX(KeyID) FROM APHB WHERE APRef = @APRef)

IF (@KeyID IS NULL)
BEGIN
	SELECT @KeyID = 0, @rcode=1
END
ELSE
BEGIN
	SELECT @rcode=0
END

END TRY
BEGIN CATCH
	SELECT @KeyID = 0, @rcode=1
END CATCH

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO