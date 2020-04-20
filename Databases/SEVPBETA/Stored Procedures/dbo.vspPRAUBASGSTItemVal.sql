SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUItemVal    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUBASGSTItemVal]
/***********************************************************/
-- CREATED BY: MV 03/08/11 #138181
-- MODIFIED BY:		CHS	03/23/2011 - fixed puntuation. 
--
-- USAGE:
-- Validates Australia BAS GST Item returns description.
-- Called from PRAUBASProcessGSTTaxCodes. 
--
-- INPUT PARAMETERS
--   @GSTItem	GST Item
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs otherwise returns  Description from vPRAUBASGSTItems
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
-- TEST HARNESS
--
--	DECLARE	@ReturnCode int,
--			@Message varchar(60)
--
--	EXEC	@ReturnCode = [dbo].[vspPRAUBASGSTItemVal]
--			@GSTItem = 'G1',
--			@Message = @Message OUTPUT
--
--	SELECT	@ReturnCode as 'Return Code', @Message as '@Message'
--
/******************************************************************/
(
@GSTItem char(3) = null,
@Message varchar(60) output
)

AS
SET NOCOUNT ON

IF @GSTItem IS NULL
BEGIN
	SELECT @Message = 'Missing GST Item!'
	RETURN 1
END


SELECT @Message = Description 
FROM dbo.PRAUBASGSTItems
WHERE GSTItem = @GSTItem  
IF @@ROWCOUNT = 0
BEGIN
	SELECT @Message = 'GST Item is invalid!'
	RETURN 1
END

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASGSTItemVal] TO [public]
GO
