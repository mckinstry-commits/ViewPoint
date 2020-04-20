SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGEmployeeAmountsGenerate    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGEmployeeAmountsGenerate]
/***********************************************************/
-- CREATED BY: EN 3/12/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Initializes the PAYG ATO/Super and Misc Amounts for a specific employee.  Detects based on the EndDate whether the full
-- year needs to be initialized or a partial summary or whether a partial summary is being replaced. 
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

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGEmployeeAmountsGenerate]
--			@PRCo = 204,
--			@TaxYear = '2010',
--			@Employee = 17,
--			@EndDate = '5/01/2009',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as 'Error Message'
--
/******************************************************************/
(
 @PRCo bCompany = NULL,
 @TaxYear char(4) = NULL,
 @Employee bEmployee = NULL,
 @EndDate bDate = NULL,
 @Message varchar(4000) output
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ReturnCode int
	
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

	--STEP 1 OF 4: DETERMINE BEGINDATE AND SUMMARY SEQ TO UPDATE

	--determine first and last date in tax year
	DECLARE @TaxYearBeginDate bDate, @TaxYearEndDate bDate

	SELECT @TaxYearBeginDate = '07/01/' + CAST((CAST(@TaxYear AS smallint) - 1) AS char(4))
	SELECT @TaxYearEndDate = '06/30/' + CAST(CAST(@TaxYear AS smallint) AS char(4))

	--partial summaries are stored in vPRAUEmployeeItemAmounts and vPRAUEmployeeMiscItemAmounts
	--load an aggregate list of partial summaries for this employee into @PartialSummaries table variable
	DECLARE @PartialSummaries TABLE (SummarySeq tinyint,
									 BeginDate bDate,
									 EndDate bDate)

	INSERT INTO @PartialSummaries
		SELECT SummarySeq, BeginDate, EndDate FROM dbo.vPRAUEmployeeItemAmounts
		WHERE	PRCo = @PRCo
				AND TaxYear = @TaxYear
				AND Employee = @Employee
		UNION
		SELECT SummarySeq, BeginDate, EndDate FROM dbo.vPRAUEmployeeMiscItemAmounts
		WHERE	PRCo = @PRCo
				AND TaxYear = @TaxYear
				AND Employee = @Employee

	DECLARE @SummarySeqExistsYN bYN,
			@ThruDateExistsYN bYN,
			@FromDate bDate,
			@SummarySeq tinyint

	-- To determine BeginDate and SummarySeq to update, need to allow for several scenarios...
	--
	-- 1) No partial summaries exist for this employee in the employee amounts tables.  In this case BeginDate will be 
	--		set to the TaxYear Begin Date and SummarySeq will be set to 1.
	--
	-- 2) At least one partial summary exists for this employee but none for the EndDate requested.
	--		(EndDate must be greater than the max EndDate logged in employee amounts tables.)
	--		In this case BeginDate will be set to one day more than the last EndDate in employee amounts
	--		tables and SummarySeq will be set to the last SummarySeq + 1.
	--
	-- 3) A partial summary for the EndDate requested for this update exists already in employee amounts tables.  
	--		In this case BeginDate and SummarySeq will be set to those already associated with the EndDate for this employee.


	--determine if any partial summaries exist for this employee
	IF EXISTS(SELECT TOP 1 1 FROM @PartialSummaries)
	BEGIN
		SELECT @SummarySeqExistsYN = 'Y'
	END
	ELSE
	BEGIN
		SELECT @SummarySeqExistsYN = 'N'
	END

	--determine if employee already has a partial summary for the specified EndDate
	IF EXISTS(SELECT TOP 1 1 FROM @PartialSummaries WHERE EndDate = @EndDate)
	BEGIN
		SELECT @ThruDateExistsYN = 'Y'
	END
	ELSE
	BEGIN
		SELECT @ThruDateExistsYN = 'N'
	END

	--scenarios 2 and 3 apply when partial summaries exist
	IF @SummarySeqExistsYN = 'Y'
	BEGIN
		-- If employee already has a partial summary (scenario 3) expectation is that overwrite is occurring so
		--	BeginDate and SummarySeq will be copied from the pre-existing partial summary.
		-- Otherwise, a new SummarySeq will be added after the last one on file.
		IF @ThruDateExistsYN = 'Y'
		BEGIN

			--determine BeginDate/SummarySeq for scenario 3
			SELECT	@SummarySeq = SummarySeq,
					@FromDate = BeginDate 
			FROM @PartialSummaries 
			WHERE EndDate = @EndDate
		END
		ELSE
		BEGIN
			--determine BeginDate/SummarySeq for scenario 2
			SELECT @SummarySeq = MAX(SummarySeq) + 1 FROM @PartialSummaries

			SELECT @FromDate = DATEADD(day, 1, EndDate) FROM @PartialSummaries WHERE SummarySeq = @SummarySeq - 1

			IF @FromDate > @EndDate
			BEGIN
				SELECT @Message = 'Partial summary exists that is later than the End Date requested'
				RETURN 1
			END
		END
	END
	--scenario 1 applies when no partial summaries exist
	ELSE
	BEGIN
		--determine BeginDate/SummarySeq for scenario 1
		SELECT	@SummarySeq = 1,
				@FromDate = @TaxYearBeginDate
	END


	--STEP 2 OF 4: DETERMINE PARAMETERS TO USE FOR GETTING AMOUNTS

	DECLARE	@SummaryBeginMonth bDate,
			@EndMonth bDate,
			@FBTBeginMonth bDate, 
			@FBTEndMonth bDate,
			@FBTLastDateOfEndMonth bDate,
			@LastSummaryDate bDate,
			@FirstMonthIsPartialYN bYN,
			@PRAUBeginMonth bDate,
			@PRAUEndMonth bDate,
			@PartialMonthThruDate bDate,
			@LastDateOfEndMonth bDate
			

	-- Determine month range covered by this Summary including partial month and beginning and/or end of Summary		
	SELECT	@SummaryBeginMonth = DATEADD(Day, (DATEPART(dd, @FromDate) - 1) * - 1, @FromDate),
			@EndMonth = DATEADD(Day, (DATEPART(dd, @EndDate) - 1) * - 1, @EndDate)

	-- Determine whether or not the first month of the Summary is a partial month
	-- If this is the case then amounts for that month will need to come from PRDT (amount detail)
	--  and the beginning month (to search in accumulations) will increment by one
	IF @FromDate <> @SummaryBeginMonth
	BEGIN
		SELECT @FirstMonthIsPartialYN = 'Y'
		SELECT @PartialMonthThruDate = (CASE WHEN @EndDate < DATEADD(Day, -1, DATEADD(Month, 1, @SummaryBeginMonth))
											 THEN @EndDate
											 ELSE DATEADD(Day, -1, DATEADD(Month, 1, @SummaryBeginMonth)) END)
		SELECT @PRAUBeginMonth = DATEADD(Month, 1, @SummaryBeginMonth)
		SELECT @PRAUEndMonth = @EndMonth
	END
	ELSE
	BEGIN
		SELECT @FirstMonthIsPartialYN = 'N'
		SELECT @PRAUBeginMonth = @SummaryBeginMonth
		SELECT @PRAUEndMonth = @EndMonth
	END

	-- Last Date of the End Month is used to find PRDT amounts.  If the End Month is a partial month, the accumulations
	-- for that month need to be adjusted by subtracting the PRDT amounts for that portion of the month after the Thru Date. 
	SELECT @LastDateOfEndMonth = DATEADD(Day, -1, DATEADD(Month, 1, @EndMonth))

	-- Determine the Begin/End Month & Date parameters to use when searching for Fringe Benefit amounts
	IF @FromDate > '03/31/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
	BEGIN
		-- If this summary begins after the FBT reporting cutoff, do not report Fringe Benefits as they
		-- will be reported in the following tax year's summary(s)
		SELECT @FBTBeginMonth = NULL, @FBTEndMonth = NULL
	END
	ELSE
	BEGIN
		-- FBT Begin Month is the same as Begin Month determined for searching PRAU ... however if that is
		-- the first day of the tax year, FBT Begin Month is pushed back to April 1st.
		IF @PRAUBeginMonth <> @TaxYearBeginDate
		BEGIN
			SELECT @FBTBeginMonth = @PRAUBeginMonth
		END
		ELSE
		BEGIN
			SELECT @FBTBeginMonth = '04/01/' + CAST((CAST(@TaxYear AS smallint) - 1) AS char(4))
		END	
		
		
		-- FBT End Month is generally the same as End Month determined for searching PRAU ... however must be no later than
		-- March 31st of the tax year.
		IF @EndMonth < '03/01/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
		BEGIN
			SELECT @FBTEndMonth = @EndMonth
		END
		ELSE
		BEGIN
			SELECT @FBTEndMonth = '03/01/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
		END
		
		-- FBT Thru Date is generally the same as Thru Month determined for searching accums ... however must be no later
		-- than March 31st of the tax year.
		SELECT @FBTLastDateOfEndMonth = (
										 CASE WHEN @LastDateOfEndMonth < '03/31/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
										 THEN @LastDateOfEndMonth
										 ELSE '03/31/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
										 END
										)
		IF @LastDateOfEndMonth < '03/31/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
		BEGIN
			SELECT @FBTLastDateOfEndMonth = @LastDateOfEndMonth
		END
		ELSE
		BEGIN
			SELECT @FBTLastDateOfEndMonth = '03/31/' + CAST(CAST(@TaxYear AS smallint) AS char(4))
		END
	END


	--STEP 3 OF 4: IDENTIFY POSSIBLE DATA IMPEDIMENTS

	-- VERIFY that all payments to be included in update have been updated to bPREA
	--	(for PRSQ.PaidDate between BeginDate and EndDate, make sure OldMth is not null in associated PRDT entries)
	DECLARE @PRGroup bGroup,
			@PREndDate bDate

	; --semi-colon required to use WITH
	WITH UNPOSTEDPAYPERIODS (PREndDate, PRGroup)
	AS
		(
		SELECT DISTINCT PRDT.PREndDate, PRDT.PRGroup
				FROM dbo.bPRDT PRDT (nolock)
				JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo 
												AND PRSQ.PRGroup = PRDT.PRGroup 
												AND PRSQ.PREndDate = PRDT.PREndDate 
												AND PRSQ.Employee = PRDT.Employee
												AND PRSQ.PaySeq = PRDT.PaySeq
				WHERE PRDT.PRCo = @PRCo AND PRDT.Employee = @Employee 
					  AND PRSQ.PaidDate BETWEEN @FromDate AND @EndDate 
					  AND PRSQ.CMRef IS NOT NULL
					  AND PRDT.OldMth IS NULL
		)

	SELECT TOP(1) @PRGroup = PRGroup, @PREndDate = PREndDate FROM UNPOSTEDPAYPERIODS ORDER BY PREndDate ASC

	IF @PRGroup IS NOT NULL
	BEGIN
		SELECT @Message =	'Amounts for PR Group ' + CONVERT(varchar, @PRGroup)
							+ ', Pay Period Ending ' + CONVERT(varchar, @PREndDate, 103)
							+ ' has not yet been posted to Employee Accumulations.  Please run Ledger Update.'
		RETURN 1
	END

	-- VERIFY that employee does not have lump sum A amounts for both type R and T
	DECLARE @EmployerItems TABLE (	ItemCode char(4),
									EDLType char(1),
									EDLCode bEDLCode)

	INSERT INTO @EmployerItems (ItemCode, EDLType, EDLCode)
	SELECT	ItemCode, EDLType, EDLCode 
		FROM dbo.vPRAUEmployerATOItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear
	UNION
	SELECT	ItemCode, DLType AS [EDLType], DLCode AS [EDLCode] 
		FROM dbo.vPRAUEmployerSuperItems 
		WHERE	PRCo = @PRCo AND TaxYear = @TaxYear

	SELECT Items.ItemCode, 
		   (CASE PREC.ATOCategory WHEN 'LSAT' THEN 'T' WHEN 'LSAR' THEN 'R' ELSE NULL END)
		FROM @EmployerItems Items
		JOIN dbo.bPREA PREA (nolock) ON PREA.EDLType = Items.EDLType AND PREA.EDLCode = Items.EDLCode
		JOIN dbo.bPREC PREC (nolock) ON PREC.PRCo = PREA.PRCo AND PREA.EDLType = 'E' AND PREC.EarnCode = PREA.EDLCode
		WHERE	PREA.PRCo = @PRCo AND PREA.Employee = @Employee
				AND PREA.Mth BETWEEN @FromDate AND @PartialMonthThruDate 
				AND Items.ItemCode = 'LSA '
		GROUP BY Items.ItemCode, PREC.ATOCategory

	IF @@ROWCOUNT > 1
	BEGIN
		SELECT @Message = 'Employee ' + CONVERT(varchar, 1) + ' has both R and T Lump Sum A amounts.  Please resolve.'
	END


	--STEP 4 OF 4: INITIALIZE AMOUNTS
	BEGIN TRY
		BEGIN TRAN
		
		DECLARE @RowsAddedUpdated int
		SELECT @RowsAddedUpdated = 0

		-- CLEAR OLD AMOUNTS if overwriting previously created partial summary
		IF @ThruDateExistsYN = 'Y'
		BEGIN
			DELETE FROM dbo.vPRAUEmployeeItemAmounts
			WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND Employee = @Employee AND SummarySeq = @SummarySeq

			DELETE FROM dbo.vPRAUEmployeeMiscItemAmounts
			WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND Employee = @Employee AND SummarySeq = @SummarySeq
		END

		-- ADD EMPLOYEE HEADER if it does not already exist
		IF NOT EXISTS (	SELECT TOP 1 1 FROM dbo.vPRAUEmployees 
						WHERE PRCo = @PRCo AND TaxYear = @TaxYear AND Employee = @Employee)
		BEGIN
			INSERT INTO dbo.vPRAUEmployees (PRCo, TaxYear, Employee, Surname, GivenName, [Address], City, [State],
											Postcode, BirthDate, TaxFileNumber, PensionAnnuity, AmendedReport, AmendedEFile)
			SELECT @PRCo, @TaxYear, @Employee, LastName, FirstName, SUBSTRING([Address],1,40), SUBSTRING(City, 1, 30),
				   [State], Zip, BirthDate, REPLACE(SSN,'-',''), 'N', 'N', 'N'
				FROM dbo.bPREH
				WHERE PRCo = @PRCo AND Employee = @Employee
		END

		-- GET DATA to populate vPRAUEmployeeItemAmounts
		DECLARE @ItemAmounts TABLE (ItemCode char(4), EDLType char(1), Amount bDollar, LSAType char(1))

		INSERT @ItemAmounts
		EXEC	@ReturnCode = [dbo].[vspPRAUPAYGEmplItemAmountsGet]
				@PRCo,
				@TaxYear,
				@Employee,
				@FirstMonthIsPartialYN,
				@FromDate,
				@PartialMonthThruDate,
				@PRAUBeginMonth,
				@PRAUEndMonth,
				@FBTBeginMonth,
				@FBTEndMonth,
				@EndDate,
				@LastDateOfEndMonth,
				@FBTLastDateOfEndMonth,
				@Message OUTPUT
		-- POPULATE vPRAUEmployeeItemAmounts
		INSERT INTO dbo.vPRAUEmployeeItemAmounts (PRCo, TaxYear, Employee, ItemCode, BeginDate, EndDate, SummarySeq, Amount)
		SELECT @PRCo, @TaxYear, @Employee, ItemCode, @FromDate, @EndDate, @SummarySeq, SUM(Amount) 
			FROM @ItemAmounts GROUP BY ItemCode
		-- Track the # of rows added ... if no amounts are found, we'll need to ROLLBACK TRANS	
		SELECT @RowsAddedUpdated = @RowsAddedUpdated + @@ROWCOUNT

		-- GET DATA to populate vPRAUEmployeeMiscItemAmounts
		DECLARE @MiscAmounts TABLE (ItemCode char(4), EDLType char(1), EDLCode bEDLCode, Amount bDollar)

		INSERT @MiscAmounts
		EXEC	@ReturnCode = [dbo].[vspPRAUPAYGEmplMiscAmountsGet]
				@PRCo,
				@TaxYear,
				@Employee,
				@FirstMonthIsPartialYN,
				@FromDate,
				@PartialMonthThruDate,
				@PRAUBeginMonth,
				@PRAUEndMonth,
				@EndDate,
				@LastDateOfEndMonth,
				@Message OUTPUT
		-- POPULATE vPRAUEmployeeMiscItemAmounts
		INSERT INTO dbo.vPRAUEmployeeMiscItemAmounts (PRCo, TaxYear, Employee, ItemCode, BeginDate, EndDate, SummarySeq, 
													  EDLType, EDLCode, Amount, AllowanceDesc)
		SELECT @PRCo, @TaxYear, @Employee, ItemCode, @FromDate, @EndDate, @SummarySeq, 
			   EDLType, EDLCode, SUM(Amount), 
			   (CASE WHEN MiscAmounts.ItemCode = 'A   ' THEN PREC.Description ELSE NULL END)
			FROM @MiscAmounts MiscAmounts
			LEFT JOIN dbo.bPREC PREC ON PREC.PRCo = @PRCo AND MiscAmounts.EDLType = 'E' AND PREC.EarnCode = MiscAmounts.EDLCode
			GROUP BY ItemCode, EDLType, EDLCode, [Description]
		-- Track the # of rows added ... if no amounts are found, we'll need to ROLLBACK TRANS	
		SELECT @RowsAddedUpdated = @RowsAddedUpdated + @@ROWCOUNT
--KK Testing--------------------------------
--SELECT @Message = 'PRCo: '+ convert(varchar, @PRCo)
--RETURN 1
------------------------------------------
		-- COMMIT the changes if amounts found, otherwise ROLLBACK
		IF @RowsAddedUpdated > 0
		BEGIN
			COMMIT TRAN
		END
		ELSE
		BEGIN
			ROLLBACK TRAN
			SELECT @Message = 'No PAYG Amounts were found.  No changes made.'
			RETURN 2	-- This message is only needed when generating amounts for a single employee.  In those
						-- cases this proc is called directly from the front-end (DataAccess ATOData.cs) which simply
						-- reports error messages returned regardless of number returned.  
						-- However, when generating for all employees this proc is entered via
						-- vspPRAUPAYGGenerateAllEmployees which recognises the return value of 2 as not needing 
						-- to report an error.
		END

	END TRY

	BEGIN CATCH
		-- ROLLBACK Transaction, if error is caught
		SET @Message = ERROR_MESSAGE()
		RAISERROR (@Message, 15, 1)
		
		IF @@TRANCOUNT > 0 
		BEGIN 
			ROLLBACK TRAN 
		END
		
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGEmployeeAmountsGenerate] TO [public]
GO
