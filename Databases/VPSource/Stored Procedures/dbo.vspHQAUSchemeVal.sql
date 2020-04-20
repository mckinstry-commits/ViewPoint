SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[vspHQAUSchemeVal]
/***********************************************************/
-- CREATED BY:		EN	01/26/2011
-- MODIFIED BY:		CHS	04/30/2012
--
-- USAGE:
-- Validates Australia Scheme ID against data in vPRAUSuperSchemes. 
-- This procedure returns the Scheme Name if the Scheme ID is found to be valid.
--
-- INPUT PARAMETERS
--   @SchemeID	Code to validate
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs otherwise returns Scheme Name from vPRAUSuperSchemes	
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
--	EXEC	@ReturnCode = [dbo].[vspPRAUSchemeVal]
--			@SchemeID = 1,
--			@Message = @Message OUTPUT
--
--	SELECT	@ReturnCode as 'Return Code', @Message as '@Message'
--
/******************************************************************/
(
	@SchemeID smallint = null, 
	@InvalidMessage char(1) = 'Y',
	@Message varchar(60) output
)

AS
SET NOCOUNT ON

IF @SchemeID IS NULL
BEGIN
	SELECT @Message = 'Missing Scheme ID!'
	RETURN 1
END

--need to also check tax year range
SELECT @Message = Name 
FROM dbo.HQAUSuperSchemes 
WHERE SchemeID = @SchemeID  

IF @@ROWCOUNT = 0
BEGIN
	IF @InvalidMessage = 'Y'
		BEGIN
		SELECT @Message = 'Scheme ID is invalid!'
		RETURN 1		
		END

END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspHQAUSchemeVal] TO [public]
GO
