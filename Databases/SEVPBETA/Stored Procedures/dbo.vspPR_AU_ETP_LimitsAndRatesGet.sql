SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_ETP_LimitsAndRatesGet]
/***********************************************************/
-- CREATED BY: EN 3/14/2013  TFS-39858
-- MODIFIED BY: 
--
-- USAGE:
-- Reads ATO-provided information stored in table vPRAULimitsAndRates
-- that is used in Australian ETP reporting and taxation.
--
-- This stored procedure is called from vspPRAUPAYGEmplItemAmountsGet and
-- vspPR_AU_ETP_TaxComputations.
-- 
--
-- INPUT PARAMETERS
--	 @ThruDate			Used to assure that the values under the correct effective date are accessed and returned
--
-- OUTPUT PARAMETERS
--   @ETPCap
--   @WholeIncomeCap 
--   @RedundancyTaxFreeBasis
--   @RedundancyTaxFreeYears
--   @UnderPreservationAgePct
--   @OverPreservationAgePct
--   @ExcessCapPct
--	 @AnnualLeaveLoadingPct
--   @LeaveFlatRatePct
--	 @LeaveFlatRateLimit
--   @errmsg					Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @ThruDate bDate = NULL,
 @ETPCap bDollar OUTPUT, 
 @WholeIncomeCap bDollar OUTPUT, 
 @RedundancyTaxFreeBasis bDollar OUTPUT,
 @RedundancyTaxFreeYears bDollar OUTPUT, 
 @UnderPreservationAgePct bPct OUTPUT,
 @OverPreservationAgePct bPct OUTPUT, 
 @ExcessCapPct bPct OUTPUT, 
 @AnnualLeaveLoadingPct bPct OUTPUT,
 @LeaveFlatRatePct bPct OUTPUT,
 @LeaveFlatRateLimit bDollar OUTPUT,
 @errmsg varchar(1000) OUTPUT
)
AS
SET NOCOUNT ON

DECLARE @ReturnCode int
SET		@ReturnCode = 0

BEGIN TRY
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @ThruDate IS NULL
		BEGIN
			SET @ReturnCode = 1
			SET @errmsg = 'Missing Through Date!'
			GOTO vspExit
		END

	-------------------------------------------------------------
	-- READ MOST RECENT ETP REPORTING AND TAXATION INFORMATION --
	-------------------------------------------------------------
	DECLARE @MaxEffectiveDate bDate

	SELECT	@MaxEffectiveDate = MAX(EffectiveDate)

	FROM	dbo.vPRAULimitsAndRates
	WHERE	EffectiveDate <= @ThruDate 


	SELECT	@ETPCap = ETPCap, 
			@WholeIncomeCap = WholeIncomeCap, 
			@RedundancyTaxFreeBasis = RedundancyTaxFreeBasis,
			@RedundancyTaxFreeYears = RedundancyTaxFreeYears,
			@UnderPreservationAgePct = UnderPreservationAgePct,
			@OverPreservationAgePct = OverPreservationAgePct,
			@ExcessCapPct = ExcessCapPct, 
			@AnnualLeaveLoadingPct = AnnualLeaveLoadingPct,
			@LeaveFlatRatePct = LeaveFlatRatePct,
			@LeaveFlatRateLimit = LeaveFlatRateLimit

	FROM	dbo.vPRAULimitsAndRates
	WHERE	EffectiveDate = @MaxEffectiveDate

	-----------------------------------------------------------------------
	-- THROW ERROR IF A VALID SET OF LIMITS AND RATES CAN NOT BE LOCATED --
	-----------------------------------------------------------------------
	IF @@ROWCOUNT = 0 
	BEGIN
		SET @ReturnCode = 1
		SET @errmsg = 'Limits and Rates that are effective through: ' + dbo.vfToString(@ThruDate) + ' can not be found.'
		GOTO vspExit
	END

END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @ReturnCode = 1
	SET @errmsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @ReturnCode
GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_LimitsAndRatesGet] TO [public]
GO
