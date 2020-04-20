SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGSummaryEndDateVal    Script Date: 8/28/99 9:33:18 AM ******/
create  PROC [dbo].[vspPRAUPAYGSummaryEndDateVal]
/***********************************************************/
-- CREATED BY: EN 3/24/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Validates the End Date to make sure it is valid in vPRAUEmployeeItemAmounts and/or vPRAUEmployeeMiscItemAmounts.
--
-- INPUT PARAMETERS
--   @PRCo		PR Company
--   @TaxYear	Tax Year
--	 @Employee	Employee
--	 @EndDate	Ending Date of pay date range to update
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
-- TEST HARNESS
--
-- DECLARE	@ReturnCode int,
--			@Message varchar(60)

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGSummaryEndDateVal]
--			@PRCo = 204,
--			@TaxYear = '2010',
--			@Employee = 17,
--			@EndDate = '5/01/2009',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as 'Error Message'
--
/******************************************************************/
(
@PRCo bCompany = null,
@TaxYear char(4) = null,
@Employee bEmployee = null,
@EndDate bDate = null,
@BeginDate bDate output,
@SummarySeq tinyint output,
@Message varchar(4000) output
)
AS
BEGIN
	SET NOCOUNT ON

	-- Check Parameters
	IF @PRCo IS NULL
	BEGIN
		SELECT @Message = 'Missing PR Company!'
		RETURN 1
	END
	IF @TaxYear IS NULL
	BEGIN
		SELECT @Message = 'Missing Tax Year!'
		RETURN 1
	END
	IF @Employee IS NULL
	BEGIN
		SELECT @Message = 'Missing Employee!'
		RETURN 1
	END
	IF @EndDate IS NULL
	BEGIN
		SELECT @Message = 'Missing Ending Date!'
		RETURN 1
	END

	-- determine if partial summaries currently exist
	IF EXISTS	(SELECT TOP 1 1 FROM dbo.vPRAUEmployeeItemAmounts
				 WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND Employee = @Employee)
	BEGIN
		-- determine if partial summary currently exists for this end date
		SELECT @SummarySeq = SummarySeq, @BeginDate = BeginDate 
		FROM dbo.vPRAUEmployeeItemAmounts
		WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND Employee = @Employee AND EndDate = @EndDate

		IF @@ROWCOUNT > 0 
		BEGIN
			--partial summary exists for this end date ... return BeginDate/SummarySeq
			RETURN 0
		END
		ELSE
		BEGIN
			--partial summaries exist but none with this end date ... return error
			SELECT @Message = 'Summary for this End Date does not exist'
			RETURN 1
		END
	END
	ELSE
	BEGIN
		--no partial summaries exist ... return error
		SELECT @Message = 'Summary for this End Date does not exist'
		RETURN 1
	END

END
GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGSummaryEndDateVal] TO [public]
GO
