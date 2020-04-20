SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPR_AU_ETP_TaxComputations]
/************************************************************************
* CREATED:	DAN SO 03/07/2013 - TFS: User Story 39860:PR ETP Redundancy Tax Calculations - 1
*							  - Co-developed with Ellen BN
* MODIFIED:	EN 4/5/2013 Story 44310 / Task 45407  Added solution for ignoring days without pay
*			DAN SO 05/21/2013 - Story 50738 - return Eligible amount
*
*
* Purpose of Stored Procedure
*
*    This is the head/main procedure to calculate AU ETP Taxes
*    
* 
* INPUT
*	@PRCo				- PR Company
*	@Employee			- Employee number
*	@PREndDate			- Employee Last Payroll Date
*	@ATOETPType			- ATO ETP Type (ETPR, ETPV, ETP, ETPD, ETPU)
*	@SubjectAmt			- Amount on which to base the tax computation
*
* OUTPUT
*	@TotalAmtWithheld	- Total Amount Withheld
*	@ETPTaxableAmt		- Amount to be taxed
*	@rcode				- Return Code - (0)Successful, (1)Failure
*	@ErrorMsg			- Error Message
*************************************************************************/
(@PRCo bCompany = NULL, @Employee bEmployee = NULL, @PREndDate bDate = NULL,
 @ATOETPType VARCHAR(4) = NULL, @SubjectAmt bDollar = 0, 
 @TotalAmtWithheld bDollar OUTPUT,	@ETPTaxableAmt bDollar OUTPUT,
 @ErrorMsg VARCHAR(255) OUTPUT)

AS

BEGIN TRY

	SET NOCOUNT ON

    DECLARE @NoTFNPct bPct,
			@ForeignResPct bPct,
			@DelayPayPct bPct,
			@UseSubjectAmtYN bYN,	
			@RetVal INT,
			@rcode INT


	------------------
	-- PRIME VALUES --
	------------------
	SET @NoTFNPct = .465
	SET @ForeignResPct = .450
	SET @DelayPayPct = .315
	SET @UseSubjectAmtYN = 'Y'	
	SET @ETPTaxableAmt = 0.00
    SET @rcode = 0
    SET @ErrorMsg = ''


	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @PRCo IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing PR Company!'
			GOTO vspExit
		END
		
	IF @Employee IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Employee!'
			GOTO vspExit
		END

	IF @PREndDate IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Payroll Date!'
			GOTO vspExit
		END

	IF @ATOETPType IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing ATO ETP Type!'
			GOTO vspExit
		END		

	IF @SubjectAmt IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Subject Amount!'
			GOTO vspExit
		END		


	-------------------
	-- GET DB VALUES --
	-------------------
	---------------------------------------------------------------------------
	-- Retrieve ATO-provided information stored in table vPRAULimitsAndRates --
	---------------------------------------------------------------------------
	DECLARE	@Return_Value int
	
	DECLARE	@ThruDate bDate,
			@ETPCap bDollar,
			@WholeIncomeCap bDollar,
			@RedundancyTaxFreeBasis bDollar,
			@RedundancyTaxFreeYears bDollar,
			@UnderPreservationAgePct bPct,
			@OverPreservationAgePct bPct,
			@ExcessCapPct bPct,
			@AnnualLeaveLoadingPct bPct,
			@LeaveFlatRatePct bPct,
			@LeaveFlatRateLimit bDollar

	SET @ThruDate = @PREndDate

	-- GET DATA FROM PRAULimitsAndRates TABLE --
	EXEC	@Return_Value = [dbo].[vspPR_AU_ETP_LimitsAndRatesGet]
			@ThruDate,
			@ETPCap OUTPUT,
			@WholeIncomeCap OUTPUT,
			@RedundancyTaxFreeBasis OUTPUT,
			@RedundancyTaxFreeYears OUTPUT,
			@UnderPreservationAgePct OUTPUT,
			@OverPreservationAgePct OUTPUT,
			@ExcessCapPct OUTPUT,
			@AnnualLeaveLoadingPct OUTPUT,
			@LeaveFlatRatePct OUTPUT,
			@LeaveFlatRateLimit OUTPUT,
			@ErrorMsg OUTPUT
	
	IF @Return_Value = 1 
	BEGIN
		SET @rcode = 1
		GOTO vspExit
	END


	----------
	-- PREH --
	----------
	DECLARE	@BirthDate bDate, @HireDate bDate, @SeparationDate bDate,
			@TFNSuppliedYN bYN, @ForeignResidentYN bYN, @EmployeeGender CHAR(1)
			
	SELECT	@BirthDate = BirthDate, 
			@SeparationDate = RecentSeparationDate, 
			@HireDate = (CASE WHEN RecentRehireDate IS NULL THEN HireDate ELSE RecentRehireDate END),
			@TFNSuppliedYN = CASE WHEN SSN IS NULL THEN 'N' ELSE 'Y' END,
			@ForeignResidentYN = NonResAlienYN,
			@EmployeeGender = Sex
	  FROM	dbo.bPREH WITH (NOLOCK)
	 WHERE	PRCo = @PRCo
	   AND	Employee = @Employee

	-- MAKE SURE WE HAVE EMPLOYEE DATA --
	IF @@ROWCOUNT = 0 
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Unable to retrieve data for Employee: ' + dbo.vfToString(@Employee)
			GOTO vspExit
		END
	

	------------------------------------
	-- GET Redundancy TAX FREE AMOUNT --  ONLY FOR ETPR
	------------------------------------
	DECLARE @RedundancyTaxFreePortion bDollar, @RedundancyTaxablePortion bDollar
	SET @RedundancyTaxFreePortion = 0.00
	SET @RedundancyTaxablePortion = 0.00

	-- USED ONLY FOR Early Retirement & Genuine Redundancy --
	IF @ATOETPType = 'ETPR'
		BEGIN
			EXEC @rcode = [dbo].[vspPR_AU_ETP_RedundancyTaxFreeGet]
						@PRCo, @Employee, @UseSubjectAmtYN,
						@SubjectAmt, @HireDate, @SeparationDate,
						@RedundancyTaxFreeBasis, @RedundancyTaxFreeYears,
						@RedundancyTaxFreePortion OUTPUT,
						@RedundancyTaxablePortion OUTPUT,
						@ErrorMsg OUTPUT
				
			-- VERIFY SP SUCCESSFUL EXECUTION --
			IF @rcode <> 0 GOTO vspExit
		END 


	------------------------------------
	-- GET Invalidity TAX FREE AMOUNT --  ONLY FOR ETPV
	------------------------------------
	DECLARE @InvalidityTaxFreePortion bDollar, @InvalidityTaxablePortion bDollar
	SET @InvalidityTaxFreePortion = 0.00
	SET @InvalidityTaxablePortion = 0.00

	-- USED ONLY FOR Permanent Disability/Invalidity --   
	IF @ATOETPType = 'ETPV'
		BEGIN
			EXEC @rcode = [dbo].[vspPR_AU_ETP_InvalidityTaxFreeGet]
							@PRCo = @PRCo, 
							@Employee = @Employee,
							@ETPAmt = @SubjectAmt, 
							@BirthDate = @BirthDate, 
							@HireDate = @HireDate, 
							@SeparationDate = @SeparationDate,
							@EmployeeGender = @EmployeeGender,
							@InvalidityTaxFreePortion = @InvalidityTaxFreePortion OUTPUT, 
							@InvalidityTaxablePortion = @InvalidityTaxablePortion OUTPUT,
							@ErrorMsg = @ErrorMsg OUTPUT

			-- VERIFY SP SUCCESSFUL EXECUTION --
			IF @rcode <> 0 GOTO vspExit
		END


	--------------------------------
	-- GET PRE 83 TAX FREE AMOUNT -- FOR ALL ETPs
	--------------------------------
	DECLARE @Pre83TaxFreePortion bDollar,  @Pre83TaxablePortion bDollar
	SET @Pre83TaxFreePortion = 0.00
	SET @Pre83TaxablePortion = 0.00

	-- Based on the taxable portion of the ETP --
	SELECT @SubjectAmt = 
				CASE @ATOETPType
					WHEN 'ETPR' THEN @RedundancyTaxablePortion
					WHEN 'ETPV' THEN @InvalidityTaxablePortion
					ELSE @SubjectAmt
					END

	EXEC @rcode = [dbo].[vspPR_AU_ETP_Pre83TaxFreeGet]
					@PRCo, @Employee,
					@SubjectAmt, @HireDate, @SeparationDate,
					@Pre83TaxFreePortion OUTPUT,
					@Pre83TaxablePortion OUTPUT,   --- this becomes new subjedctamt or etptaxable amt
					@ErrorMsg OUTPUT
				
	-- VERIFY SP SUCCESSFUL EXECUTION --
	IF @rcode <> 0 GOTO vspExit


	-----------------------------------------------------------------------------------
	-- @Pre83TaxablePortion IS NOW THE ETP PORTION THAT IS SUBJECT TO Caps AND Rates --
	-----------------------------------------------------------------------------------
	SET @ETPTaxableAmt = @Pre83TaxablePortion 
	IF @ETPTaxableAmt < 0  SET @ETPTaxableAmt = 0	-- 50738 --


	-------------------------------------------
	-- IS Employee Under Preservation Age YN -- FOR ALL ETPs
	-------------------------------------------
	DECLARE @UnderPreservationAgeYN bYN

	EXEC @rcode = [dbo].[vspPR_AU_UnderPreservationAgeYN]
					@BirthDate,
					@UnderPreservationAgeYN OUTPUT,
					@ErrorMsg OUTPUT
				
	-- VERIFY SP SUCCESSFUL EXECUTION --
	IF @rcode <> 0 GOTO vspExit


	-----------------------
	-- SET ETP TAX RATES --  FOR ALL ETPs
	-----------------------
	DECLARE @UpToCapPct bPct,
			@AboveCapPct bPct

	EXEC @rcode = [dbo].[vspPR_AU_ETP_TaxRatesGet] 
					@ATOETPType, @UnderPreservationAgePct, @OverPreservationAgePct, 
					@ExcessCapPct, @NoTFNPct, @ForeignResPct, @DelayPayPct, 
					@UnderPreservationAgeYN, @TFNSuppliedYN,
					@ForeignResidentYN, @PREndDate,
					@UpToCapPct OUTPUT, @AboveCapPct OUTPUT,
					@ErrorMsg OUTPUT
				
	-- VERIFY SP SUCCESSFUL EXECUTION --
	IF @rcode <> 0 GOTO vspExit


	-------------------------------------
	-- GET TOTAL EARNINGS FOR THE YEAR -- 
	-------------------------------------
	DECLARE @YearEarnings bDollar
	SET @YearEarnings = 0.00

	-- CURRENT YEARS EARNINGS NEEDED TO CALCULATE WHOLE INCOME CAP --
	EXEC @rcode = [dbo].[vspPR_AU_TaxYearWagesGet] 
					@PRCo = @PRCo, 
					@Employee = @Employee, 
					@PREndDate = @PREndDate,
					@TaxableWages = @YearEarnings OUTPUT,
					@ErrorMsg = @ErrorMsg OUTPUT
				
	-- VERIFY SP SUCCESSFUL EXECUTION --
	IF @rcode <> 0 GOTO vspExit


	-------------------------
	-- SET ETP CAP AMOUNTS -- FOR ALL ETPS
	-------------------------
	DECLARE @UpToCapAmt bDollar,
			@AboveCapAmt bDollar,
			@CapAmt bDollar

	EXEC @rcode = [dbo].[vspPR_AU_ETP_CapAmtsGet]
					@ATOETPType = @ATOETPType, 
					@SubjectAmt = @YearEarnings, 
					@ETPAmt = @ETPTaxableAmt,
					@ETPCapAmt = @ETPCap, 
					@WholeIncomeCapAmt = @WholeIncomeCap,
					@UpToCapAmt = @UpToCapAmt OUTPUT,  
					@AboveCapAmt = @AboveCapAmt OUTPUT,
					@CapAmt = @CapAmt OUTPUT,
					@ErrorMsg = @ErrorMsg OUTPUT

	-- VERIFY SP SUCCESSFUL EXECUTION --
	IF @rcode <> 0 GOTO vspExit


	-------------------------------------------
	-- CALCULATIONS TOTAL AMOUNT TO WITHHOLD --
	-------------------------------------------
	SET @TotalAmtWithheld = (@UpToCapPct * @UpToCapAmt) + (@AboveCapPct * @AboveCapAmt)


END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @rcode = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_TaxComputations] TO [public]
GO
