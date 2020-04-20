SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRAUPAYGEDLCodeVal    Script Date: 8/28/99 9:33:18 AM ******/
CREATE PROC [dbo].[vspPRAUPAYGEDLCodeVal]
/***********************************************************/
-- CREATED BY: EN 1/10/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Validates E/D/L Codes entered in Australia PAYG ATO, Super, and Misc tabs. 
-- Code is considered valid when it exists in PREC (earnings codes) or PRDL 
-- (deduction or liability codes) and also has an ATO Category that is compatible
-- with the Item Code selected.
--
-- INPUT PARAMETERS
--   @PRCo		PR Company
--   @TaxYear	Tax Year
--   @EDLType	(E)arnings, (D)eductions, or (L)iabilities
--	 @EDLCode	Earn/Dedn/Liab Code to validate
--   @ItemCode	Item Code associated with EDLCode
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs otherwise returns the E/D/L Code Description from PREC/PRDL
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
--	EXEC	@ReturnCode = [dbo].[vspPRAUPAYGEDLCodeVal]
--			@PRCo = 69,
--			@TaxYear = 2009,
--			@EDLType = 'E',
--			@EDLCode = 160,
--			@ItemCode = 'FBT',
--			@Message = @Message OUTPUT
--
--	SELECT	@ReturnCode as 'Return Code', @Message as '@Message'
--
/******************************************************************/
(
@PRCo bCompany = null,
@TaxYear char(4) = null,
@EDLType char(1) = null,
@EDLCode bEDLCode = null, 
@ItemCode char(4) = null,
@Message varchar(60) output
)

AS
SET NOCOUNT ON

DECLARE @ATOCategory varchar(4)

IF @PRCo IS NULL
BEGIN
	SELECT @Message = 'Missing PR Company!'
	RETURN 1
END

IF @EDLType IS NULL OR @EDLType NOT IN ('E','D','L')
BEGIN
	SELECT @Message = 'Missing or invalid Earn/Dedn/Liab Type!'
	RETURN 1
END

IF @EDLCode IS NULL
BEGIN
	SELECT @Message = 'Missing Earn/Dedn/Liab Code!'
	RETURN 1
END

IF @ItemCode IS NULL
BEGIN
	SELECT @Message = 'Missing Item Code!'
	RETURN 1
END

--perform basic EDL code validation and get ATO Category
IF @EDLType='E'
BEGIN
	SELECT @Message = [Description], @ATOCategory = ATOCategory
	FROM PREC
	WHERE PRCo = @PRCo AND EarnCode = @EDLCode

	IF @@rowcount = 0
	BEGIN
		SELECT @Message = 'PR Earnings Code not on file!'
		RETURN 1
	END
END
ELSE
BEGIN
	SELECT @Message = [Description], @ATOCategory = ATOCategory
	FROM PRDL
	WHERE PRCo = @PRCo AND DLType = @EDLType AND DLCode = @EDLCode
	IF @@rowcount = 0
	BEGIN
		IF @EDLType = 'D'
		BEGIN
			SELECT @Message = 'PR Deduction Code not on file!'
			RETURN 1
		END
		IF @EDLType = 'L'
		BEGIN
			SELECT @Message = 'PR Liability Code not on file!'
			RETURN 1
		END
	END
END

--confirm that ATO Category of EDL Code works with Item Code
IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.vPRAUItemsATOCategories WHERE ItemCode = @ItemCode and ATOCategory = @ATOCategory)
BEGIN
	SELECT @Message = 'ATO Category assigned is not valid with this item code!'
	RETURN 1
END

--the end
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGEDLCodeVal] TO [public]
GO
