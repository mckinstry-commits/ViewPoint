SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRROEInitializeMain]

/*****************************************************************************************************************************

Copyright 2013 Viewpoint Construction Software. All rights reserved. 
CREATED BY:		CUC	04/22/13	TFS-39834 PR ROE Electronic File
MODIFIED BY:

INPUT PARAMETERS
 @PRCo               PR Company
 @OverwriteYN        Overwrite pre-existing records in history tables?

OUTPUT PARAMETERS
 @Msg                Processing summary message returned to caller for display on confirmation dialog

RETURN VALUES
 0                   Success (all input (workfile) records processed successfully; no system error occurred)
 1                   Failure (one or more input (workfile) records invalidated, not processed; or system error occurred)

USAGE
This is the primary procedure used in the PR module to initialize the Record of Employment (Canada).

This procedure generates ("initializes") a Record of Employment (ROE) for each of one or more employees. Specifically, 
the procedure reads and evaluates processable employee input records in the ROE workfile table (vPRROEEmployeeWorkfile), 
then calculates values and builds record sets that it inserts into the ROE history tables:
	vPRROEEmployeeHistory			"Hist"		Main history table;
	vPRROEEmployeeInsurEarningsPPD	"InsEarn"	Insurable earnings by pay period history table;
	vPRROEEmployeeSSPayments		"SSPay"		Separation and special payments history table.

This procedure executes the following helper procedures:
	vspPRROEInitializeVal			Performs extensive validation on workfile records and other required input values;
	vspPRROEInitializeLoadHist		Performs calculations, builds temp record set for insert into Hist (main) history table;
	vspPRROEInitializeLoadInsEarn	Performs calculations, builds temp record set for insert into InsEarn history table;
	vspPRROEInitializeLoadSSPay		Performs calculations, builds temp record set for insert into SSPay history table.

This procedure is contained within a single transaction (tranMain). If any system (database) error occurs within this 
procedure or any of its helper procedures, all data changes from this procedure and all helper procedures are rolled back 
(no changes are committed whatsoever), and error details are raised to the caller for display in a dialog box for the user.

-----

Below is a general overview of processing in this procedure and its helper procedures. See inline comments within procedures 
for full details. Each set of processing steps below is preceded by the name of the responsible procedure (in square brackets).

[vspPRROEInitializeMain]

1. Exit immediately if not one record is available for processing in workfile grid. This condition may occur, for instance, 
if not one record in grid is flagged ("checked") for processing.

2. If form code detected pre-existing (matching) rows in history tables, and user subsequently selected overwrite option in 
popup dialog (caller supplied value 'Y' for input parameter @OverwriteYN), delete matching rows from history tables.

[vspPRROEInitializeVal]

3. Validate data required for processing. Validation is attempted on all processable records in the workfile table. 
(A processable record is any record for the current form company, flagged for processing, and belonging to the current user.) 
Validation tests are performed in groups called "tiers". For any workfile grid record that fails validation in some tier, 
no validation tests from any subsequent tier are attempted, and all errors are reported from all tests within the tier where
the failure occurred. More general or fundamental tests appear in earlier tiers; more specific or superficial tests appear 
in later tiers. Tests are ordered and grouped in tiers such that only one error message ever appears for any given data 
deficiency: cascading errors are avoided by design. For any processable workfile grid record that fails validation, a message 
to the user is written to the workfile table detailing the data issues that require correction. Any such record persists in 
the workfile form after processing has completed, where it is presented to the user for review and remedy.

[vspPRROEInitializeMain]

4. Exit if not one processable record in workfile grid passed all validation tests.

5. Begin processing validated input records. Create main temp table (#tmptableROEMain) to hold records for insert into 
main history table (vPRROEEmployeeHistory). Each row represents an ROE for an employee. 

[vspPRROEInitializeLoadHist]

6. Insert rows (primarily from workfile table) into main temp table, including calculated values for Final Pay Period End Date.

7. Iteratively, update rows in main temp table with calculated values for Initial Pay Period End Date for Block 15a; 
Initial Pay Period End Date for Block 15b; Initial Pay Period End Date for Block 15c; Total Insurable Hours; 
Total Insurable Earnings.

[vspPRROEInitializeMain]

8. Insert rows from main temp table into main history table. Prior validation tests determined that no records existed in 
main history table (at validation time) that matched processable records in workfile table on PR Company, Employee, ROEDate, 
or on PR Company, Employee, First Day Worked, Last Day Paid. Given the slight possibility that such pre-existing records might 
exist in main history table now (at insertion time), exclude any matching rows from the selection for the insert. Use OUTPUT 
to capture in a table variable all rows actually inserted successfully into main history table. For all rows that were inserted 
successfully, update flag (InsertedHistoryYN) to 'Y' in main temp table; later, all and only such main temp table rows will be 
processed further (for subsequent inserts into insurable earnings by pay period table (InsEarn) and separation/special payments 
table (SSPay)). For all rows that were not inserted successfully into main history table, leave flag (InsertedHistoryYN) in 
main temp table set to 'N' (do not update flag), and update workfile table with appropriate error message to user and 
ValidationTier value ('99'), indicating failure to initialize.

9. Exit if not one record in main temp table was inserted successfully into main history table.

10. Create insurable earnings temp table (#tmptableROEInsEarn) to hold records for insert into InsEarn history table 
(vPRROEEmployeeInsurEarningsPPD) (Block 15c). Each row will contain the insurable earnings amount sum for a single pay period 
for an ROE for an employee.

[vspPRROEInitializeLoadInsEarn]

11. Insert rows (primarily from pay period control table bPRPC) into insurable earnings temp table. Process only 
employees whose ROE records were inserted previously into main history table successfully. For each pay period for each 
employee, sum pay sequence total amounts for insurable earnings and insurable liabilities for any pay sequence that has 
been processed. Exclude amounts associated with any "separation payment" earn code. (In subsequent update below, all insurable 
separation payment amounts will be allocated artificially to the employee's final pay period, regardless of the pay period 
in which the payments were actually made.) If, for any given pay period, the employee has no insurable earnings (other than 
separation payments), then insert a zero ('0') value (not NULL) for earnings amount indicating a "nil pay period".

12. Update rows in insurable earnings temp table, adding sum of insurable separation payment amounts to employee's final 
pay period row only.

[vspPRROEInitializeMain]

13. Insert rows from insurable earnings temp table into InsEarn history table (vPRROEEmployeeInsurEarningsPPD) (Block 15c).

14. Create sep/special payments temp table (#tmptableROESSPay) to hold records for insert into SSPay history table 
(vPRROEEmployeeSSPayments) (Blocks 17a, 17b, 17c, 19). Each row will contain special payment information, or a separation 
payment, for an ROE for an employee.

[vspPRROEInitializeLoadSSPay]

15. Insert rows (primarily from pay sequence totals table bPRDT) into sep/special payments temp table for Block 17a 
(separation payments of category 'V-Vacation'). Process only employees whose ROE records were inserted previously into main 
history table successfully. If an employee has no conforming vacation separation payments, load no row for that employee.

16. Insert rows (primarily from timecard header table bPRTH) into sep/special payments temp table for Block 17b 
(separation payments of category 'SH-Statutory Holiday'). Process only employees whose ROE records were inserted previously 
into main history table successfully. If an employee has no conforming statutory holiday separation payments, load no rows for 
that employee.

17. Insert rows (primarily from pay sequence totals table bPRDT) into sep/special payments temp table for Block 17c 
(separation payments of category 'OM-Other Monies'). Process only employees whose ROE records were inserted previously into 
main history table successfully. If an employee has no conforming other monies separation payments, load no rows for that 
employee.

18. Insert rows (primarily from timecard header table bPRTH) into sep/special payments temp table for Block 19 
(special payments (type PSL: paid sick leave; type MAT: maternity or care leave; type WLI: wage-loss indemnity)). Process 
only employees whose ROE records were inserted previously into main history table successfully. If an employee has no
special payment start date in workfile grid, or has no conforming special payments, load no row for that employee.

[vspPRROEInitializeMain]

19. Insert rows from sep/special payments temp table into SSPay history table (vPRROEEmployeeSSPayments) 
(Blocks 17a, 17b, 17c, 19).

20. Cleanup: Delete from workfile table (vPRROEEmployeeWorkfile) all and only rows that were processed successfully. Leave 
in place any processable rows that failed one or more validation tests, or were invalidated during processing; each such row 
now bears a detailed error message for presentation to the user in the refreshed workfile form.

21. Exit: Return appropriate RETURN value and processing summary message.

*****************************************************************************************************************************/

(
	@PRCo			bCompany		= NULL,
	@OverwriteYN	bYN				= NULL,
	@Msg			varchar(255)	OUTPUT
)

AS

BEGIN

	SET NOCOUNT ON


	/* Declare variables for handling system (database) errors */

	DECLARE @ErrorMessage	varchar(4000)
	DECLARE	@ErrorDetail	varchar(4000)


	BEGIN TRY											--Begin outer TRY block


		/* Validate input parameters */

		IF @PRCo IS NULL
			BEGIN
				SELECT @Msg = 'Required Company parameter (@PRCo) was not supplied by caller.'
				RETURN 1
			END
		
		IF @OverwriteYN IS NULL
			BEGIN
				SELECT @Msg = 'Required Overwrite Flag parameter (@OverwriteYN) was not supplied by caller.'
				RETURN 1
			END


		/* Exit immediately if not one record is available for processing in workfile grid */
		
		IF NOT EXISTS
		(
			SELECT	1
			FROM	dbo.vPRROEEmployeeWorkfile
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()		--Processable in workfile table
		)
			BEGIN
				SELECT @Msg = 'No records in grid were flagged for processing.'
				RETURN 1
			END


		/* Open transaction tranMain prior to any statement that could modify data in tables */
			/* In the event of a system error, all data changes will be rolled back prior to exit. In the absence of any 
			   system error, transaction will be committed at each potential exit. */

		BEGIN TRANSACTION tranMain


		/* If overwrite option was selected by user, delete matching rows from history tables */

		IF @OverwriteYN = 'Y'
			BEGIN
			
				DELETE	SSPay
				FROM	dbo.vPRROEEmployeeSSPayments SSPay
				JOIN	dbo.vPRROEEmployeeWorkfile Work ON Work.PRCo = SSPay.PRCo AND Work.Employee = SSPay.Employee AND Work.ROEDate = SSPay.ROEDate
				WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
			
				DELETE	InsEarn
				FROM	dbo.vPRROEEmployeeInsurEarningsPPD InsEarn
				JOIN	dbo.vPRROEEmployeeWorkfile Work ON Work.PRCo = InsEarn.PRCo AND Work.Employee = InsEarn.Employee AND Work.ROEDate = InsEarn.ROEDate
				WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()

				DELETE	Hist
				FROM	dbo.vPRROEEmployeeHistory Hist
				JOIN	dbo.vPRROEEmployeeWorkfile Work ON Work.PRCo = Hist.PRCo AND Work.Employee = Hist.Employee AND Work.ROEDate = Hist.ROEDate
				WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
			
			END


		/* Validate data required for processing */

		BEGIN TRY
			EXECUTE	dbo.vspPRROEInitializeVal @PRCo = @PRCo
		END TRY
		BEGIN CATCH

			SET @ErrorDetail	= 'Msg ' + CAST(ERROR_NUMBER() AS varchar(50)) + ', '
								  + 'Level ' + CAST(ERROR_SEVERITY() AS varchar(5)) + ', '
								  + 'State ' + CAST(ERROR_STATE() AS varchar(5))  + ', '
								  + 'Procedure ' + ISNULL(ERROR_PROCEDURE(),'-')  + ', '
								  + 'Line ' + CAST(ERROR_LINE() AS varchar(5))

			SET @ErrorMessage	= @ErrorDetail + CHAR(13) + CHAR(10)
								  + CHAR(9) + 'Error encountered in vspPRROEInitializeVal: ' + CHAR(13) + CHAR(10)
								  + CHAR(9) + CHAR(9) + ERROR_MESSAGE()

			RAISERROR(@ErrorMessage,16,1)				--Transfers control to outer CATCH block
			
		END CATCH


		/* Exit if not one processable record in workfile grid passed all validation tests */
		
		IF NOT EXISTS
		(
			SELECT	1
			FROM	dbo.vPRROEEmployeeWorkfile
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()		--Processable in workfile table
				AND	ValidationTier IS NULL												--Not invalidated by any validation test
		)
			BEGIN

				SELECT @Msg = 'No records flagged for processing in grid were initialized. See Error Messages in grid for data issues that require correction.'

				IF @@TRANCOUNT > 0						--Commit transaction immediately prior to exit (no sooner)
					BEGIN
						COMMIT TRANSACTION tranMain		--Commits updates in workfile table (validation failures); also deletions from history tables, if overwrite requested
					END

				RETURN 1

			END


		/* Process validated input (workfile) records */


		/* Create main temp table (#tmptableROEMain) to hold records for insert into main history table (vPRROEEmployeeHistory) */
			/* Each row represents an ROE for an employee; effective composite key is PRCo, Employee, ROEDate, although validation tests
			   (Tier 1) effectively impose uniqueness on PRCo, Employee within the set of validated, processable workfile table rows that 
			   are selected below for insert into this main temp table. */

		CREATE TABLE #tmptableROEMain
		(
			[WorkfileKeyID]					bigint			NOT NULL,				--	Source: Workfile
			[PRCo]							tinyint			NOT NULL,	--bCompany		Source: Workfile
			[Employee]						int				NOT NULL,	--bEmployee		Source: Workfile
			[ROEDate]						smalldatetime	NOT NULL,	--bDate			Source: Workfile
			[SIN]							varchar(9)		NOT NULL,				--	Source: bPREH
			[FirstName]						varchar(20)		NOT NULL,				--	Source: bPREH
			[MiddleInitial]					varchar(4)		NULL,					--	Source: bPREH
			[LastName]						varchar(28)		NOT NULL,				--	Source: bPREH
			[AddressLine1]					varchar(35)		NOT NULL,				--	Source: bPREH
			[AddressLine2]					varchar(35)		NULL,					--	Source: bPREH
			[AddressLine3]					varchar(35)		NULL,					--	Source: bPREH
			[EmployeeOccupation]			varchar(40)		NULL,					--	Source: bPROP.Description, left join from bPREH
			[FirstDayWorked]				smalldatetime	NOT NULL,	--bDate			Source: bPREH
			[LastDayPaid]					smalldatetime	NOT NULL,	--bDate			Source: bPREH
			[FinalPayPeriodEndDate]			smalldatetime	NOT NULL,	--bDate			Source: bPRPC
			[ExpectedRecallCode]			char(1)			NULL,					--	Source: Workfile
			[ExpectedRecallDate]			smalldatetime	NULL,		--bDate			Source: Workfile
			[SpecialPaymentStartDate]		smalldatetime	NULL,		--bDate			Source: Workfile (for SSPay)
			[TotalInsurableHours]			smallint		NOT NULL,				--	Calculation
			[TotalInsurableEarnings]		numeric(12,2)	NOT NULL,	--bDollar	--	Calculation
			[ReasonForROE]					char(1)			NOT NULL,				--	Source: Workfile
			[ContactFirstName]				varchar(20)		NOT NULL,				--	Source: Workfile
			[ContactLastName]				varchar(28)		NOT NULL,				--	Source: Workfile
			[ContactAreaCode]				varchar(3)		NOT NULL,				--	Source: Workfile
			[ContactPhoneNbr]				varchar(8)		NOT NULL,				--	Source: Workfile
			[ContactPhoneExt]				varchar(5)		NULL,					--	Source: Workfile
			[Comments]						varchar(160)	NULL,					--	Source: Workfile
			[PayPeriodType]					char(1)			NOT NULL,				--	Source: bPRGR.PayFreq
			[Language]						char(1)			NULL,					--	Source: Workfile
			[PRGroup]						tinyint			NOT NULL,	--bGroup		Source: bPREH
			[InitialPayPeriodEndDate15a]	smalldatetime	NULL,		--bDate			Source: bPRPC
			[InitialPayPeriodEndDate15b]	smalldatetime	NULL,		--bDate			Source: bPRPC
			[InitialPayPeriodEndDate15c]	smalldatetime	NULL,		--bDate			Source: bPRPC
			[InsertedHistoryYN]				char(1)			NOT NULL	--bYN			Process control flag
		)


		/* Load data into main temp table (#tmptableROEMain) */

		BEGIN TRY
			EXECUTE	dbo.vspPRROEInitializeLoadHist @PRCo = @PRCo
		END TRY
		BEGIN CATCH

			SET @ErrorDetail	= 'Msg ' + CAST(ERROR_NUMBER() AS varchar(50)) + ', '
								  + 'Level ' + CAST(ERROR_SEVERITY() AS varchar(5)) + ', '
								  + 'State ' + CAST(ERROR_STATE() AS varchar(5))  + ', '
								  + 'Procedure ' + ISNULL(ERROR_PROCEDURE(),'-')  + ', '
								  + 'Line ' + CAST(ERROR_LINE() AS varchar(5))

			SET @ErrorMessage	= @ErrorDetail + CHAR(13) + CHAR(10)
								  + CHAR(9) + 'Error encountered in vspPRROEInitializeLoadHist: ' + CHAR(13) + CHAR(10)
								  + CHAR(9) + CHAR(9) + ERROR_MESSAGE()

			RAISERROR(@ErrorMessage,16,1)				--Transfers control to outer CATCH block
			
		END CATCH


		/* Insert rows from main temp table (#tmptableROEMain) into main history table (vPRROEEmployeeHistory) */
			/* Prior validation tests (Tier 3) determined that no records existed in main history table (at validation time) that matched
			   processable records in workfile table (now all rows in main temp table) on PR Company, Employee, ROEDate, or on PR Company, 
			   Employee, First Day Worked, Last Day Paid. Given the slight possibility that such pre-existing records might exist in 
			   main history table now (at insertion time), exclude any matching rows from the selection for the insert. Use OUTPUT 
			   to capture in a table variable all rows actually inserted successfully into main history table. For all rows that were inserted 
			   successfully, update flag (InsertedHistoryYN) to 'Y' in main temp table; later, only such main temp table rows will be 
			   processed further (for subsequent inserts into insurable earnings by pay period table (InsEarn) and separation/special 
			   payments table (SSPay)); this will prevent the possibility of attempted insertion of "orphaned rows" into InsEarn and SSPay 
			   (rows that have no corresponding "parent row" in main history table), which would violate foreign key constraints in the tables. 
			   For all rows that were not inserted successfully into main history table, leave flag (InsertedHistoryYN) in main temp table
			   set to 'N' (do not update flag), and update workfile table with appropriate error message and ValidationTier value ('99'), 
			   indicating failure to initialize. */


		--Create table variable to hold rows inserted successfully into main history table
		DECLARE @tblvarInsertedHist table
		(
			PRCo		tinyint,		--bCompany
			Employee	int,			--bEmployee
			ROEDate		smalldatetime	--bDate
		)


		--Insert rows from main temp table into main history table, excluding any pre-existing rows
		INSERT INTO dbo.vPRROEEmployeeHistory
		(
			[PRCo],
			[Employee],
			[ROEDate],
			[ROE_SN],
			[SIN],
			[FirstName],
			[MiddleInitial],
			[LastName],
			[AddressLine1],
			[AddressLine2],
			[AddressLine3],
			[EmployeeOccupation],
			[FirstDayWorked],
			[LastDayPaid],
			[FinalPayPeriodEndDate],
			[ExpectedRecallCode],
			[ExpectedRecallDate],
			[TotalInsurableHours],
			[TotalInsurableEarnings],
			[ReasonForROE],
			[ContactFirstName],
			[ContactLastName],
			[ContactAreaCode],
			[ContactPhoneNbr],
			[ContactPhoneExt],
			[Comments],
			[AmendedDate],
			[UniqueAttchID],
			[Notes],
			[PayPeriodType],
			[Language]
		)
		OUTPUT	inserted.PRCo, inserted.Employee, inserted.ROEDate		--Inserted rows captured in table variable
		INTO	@tblvarInsertedHist (PRCo, Employee, ROEDate)
		SELECT
			'PRCo'						= tmpMain.PRCo,
			'Employee'					= tmpMain.Employee,
			'ROEDate'					= tmpMain.ROEDate,
			'ROE_SN'					= NULL,
			'SIN'						= tmpMain.[SIN],
			'FirstName'					= tmpMain.FirstName,
			'MiddleInitial'				= tmpMain.MiddleInitial,
			'LastName'					= tmpMain.LastName,
			'AddressLine1'				= tmpMain.AddressLine1,
			'AddressLine2'				= tmpMain.AddressLine2,
			'AddressLine3'				= tmpMain.AddressLine3,
			'EmployeeOccupation'		= tmpMain.EmployeeOccupation,
			'FirstDayWorked'			= tmpMain.FirstDayWorked, 
			'LastDayPaid'				= tmpMain.LastDayPaid,
			'FinalPayPeriodEndDate'		= tmpMain.FinalPayPeriodEndDate,
			'ExpectedRecallCode'		= tmpMain.ExpectedRecallCode,
			'ExpectedRecallDate'		= tmpMain.ExpectedRecallDate,
			'TotalInsurableHours'		= tmpMain.TotalInsurableHours,
			'TotalInsurableEarnings'	= tmpMain.TotalInsurableEarnings,
			'ReasonForROE'				= tmpMain.ReasonForROE,
			'ContactFirstName'			= tmpMain.ContactFirstName,
			'ContactLastName'			= tmpMain.ContactLastName,
			'ContactAreaCode'			= tmpMain.ContactAreaCode,
			'ContactPhoneNbr'			= tmpMain.ContactPhoneNbr,
			'ContactPhoneExt'			= tmpMain.ContactPhoneExt,
			'Comments'					= tmpMain.Comments,
			'AmendedDate'				= NULL,
			'UniqueAttchID'				= NULL,
			'Notes'						= NULL,
			'PayPeriodType'				= tmpMain.PayPeriodType,
			'Language'					= tmpMain.[Language]
		FROM		#tmptableROEMain tmpMain
		LEFT JOIN	dbo.vPRROEEmployeeHistory Hist1						--Joined only to exclude pre-existing rows
						ON Hist1.PRCo = tmpMain.PRCo
						AND Hist1.Employee = tmpMain.Employee
						AND Hist1.ROEDate = tmpMain.ROEDate
		LEFT JOIN	dbo.vPRROEEmployeeHistory Hist2						--Joined only to exclude pre-existing rows
						ON Hist2.PRCo = tmpMain.PRCo
						AND Hist2.Employee = tmpMain.Employee
						AND Hist2.FirstDayWorked = tmpMain.FirstDayWorked
						AND Hist2.LastDayPaid = tmpMain.LastDayPaid
		WHERE	Hist1.PRCo IS NULL										--Select only main temp table rows that have no matching (pre-existing) rows in main history table
			AND Hist2.PRCo IS NULL										--Select only main temp table rows that have no matching (pre-existing) rows in main history table


		--For each main temp table row inserted into main history table, indicate success by updating flag from 'N' to 'Y' in main temp table
		UPDATE	tmpMain
		SET		tmpMain.InsertedHistoryYN = 'Y'
		FROM	#tmptableROEMain tmpMain
		JOIN	@tblvarInsertedHist InsertedHist						--Join requires existence in table variable, which indicates successful insert
					ON InsertedHist.PRCo = tmpMain.PRCo
					AND InsertedHist.Employee = tmpMain.Employee
					AND InsertedHist.ROEDate = tmpMain.ROEDate


		--For any main temp table row not inserted into main history table, indicate failure by updating validation columns in workfile table
		--In main temp table, leave flag (InsertedHistoryYN) set at its initial value 'N', indicating failure to insert
		UPDATE	Work
		SET		Work.ValidationTier = 99,
				Work.ErrorMessage = 'Could not be initialized: '
						+ 'Record already exists in PR Record of Employment for this PR Company, Employee, ROEDate, '
						+ 'or for this PR Company, Employee, First Day Worked, Last Day Paid'
		FROM		#tmptableROEMain tmpMain
		JOIN		dbo.vPRROEEmployeeWorkfile Work
						ON Work.PRCo = tmpMain.PRCo
						AND Work.Employee = tmpMain.Employee
						AND Work.ROEDate = tmpMain.ROEDate
						AND Work.VPUserName = SUSER_SNAME()
		LEFT JOIN	@tblvarInsertedHist InsertedHist					--Left join allows for non-existence in table variable
						ON InsertedHist.PRCo = tmpMain.PRCo
						AND InsertedHist.Employee = tmpMain.Employee
						AND InsertedHist.ROEDate = tmpMain.ROEDate
		WHERE	InsertedHist.PRCo IS NULL								--Record missing from table variable, which indicates failure of insert


		/* Exit if not one record in main temp table was inserted successfully into main history table (also, all workfile rows marked as validation failures) */

		IF NOT EXISTS
		(
			SELECT	1
			FROM	#tmptableROEMain
			WHERE	InsertedHistoryYN = 'Y'				--Indicates main temp table row was inserted successfully into main history table
		)
			BEGIN

				SELECT @Msg = 'No records flagged for processing in grid were initialized. See Error Messages in grid for data issues that require correction.'

				IF @@TRANCOUNT > 0						--Commit transaction immediately prior to exit (no sooner)
					BEGIN
						COMMIT TRANSACTION tranMain		--Commits updates in workfile table (validation failures); also deletions from history tables, if overwrite requested
					END

				RETURN 1

			END


		/* Create insurable earnings temp table to hold records for insert into InsEarn history table (vPRROEEmployeeInsurEarningsPPD) (Block 15c) */
			/* Each row contains the insurable earnings amount sum for a single pay period for an ROE for an employee */
			/* Effective composite key is PRCo, Employee, ROEDate, PayPeriodEndingDate */

		CREATE TABLE #tmptableROEInsEarn
		(
			[PRCo]					tinyint			NOT NULL,	--bCompany
			[Employee]				int				NOT NULL,	--bEmployee
			[ROEDate]				smalldatetime	NOT NULL,	--bDate
			[PayPeriodEndingDate]	smalldatetime	NOT NULL,	--bDate
			[InsurableEarnings]		numeric(12,2)	NOT NULL	--bDollar
		)


		/* Load data into insurable earnings temp table (#tmptableROEInsEarn) */

		BEGIN TRY
			EXECUTE	dbo.vspPRROEInitializeLoadInsEarn
		END TRY
		BEGIN CATCH

			SET @ErrorDetail	= 'Msg ' + CAST(ERROR_NUMBER() AS varchar(50)) + ', '
								  + 'Level ' + CAST(ERROR_SEVERITY() AS varchar(5)) + ', '
								  + 'State ' + CAST(ERROR_STATE() AS varchar(5))  + ', '
								  + 'Procedure ' + ISNULL(ERROR_PROCEDURE(),'-')  + ', '
								  + 'Line ' + CAST(ERROR_LINE() AS varchar(5))

			SET @ErrorMessage	= @ErrorDetail + CHAR(13) + CHAR(10)
								  + CHAR(9) + 'Error encountered in vspPRROEInitializeLoadInsEarn: ' + CHAR(13) + CHAR(10)
								  + CHAR(9) + CHAR(9) + ERROR_MESSAGE()

			RAISERROR(@ErrorMessage,16,1)				--Transfers control to outer CATCH block
			
		END CATCH


		/* Insert rows from insurable earnings temp table into InsEarn history table (vPRROEEmployeeInsurEarningsPPD) (Block 15c) */

		INSERT INTO dbo.vPRROEEmployeeInsurEarningsPPD
		(
			[PRCo],
			[Employee],
			[ROEDate],
			[PayPeriodEndingDate],
			[InsurableEarnings]
		)
		SELECT
			'PRCo'					= tempInsEarn.PRCo,
			'Employee'				= tempInsEarn.Employee,
			'ROEDate'				= tempInsEarn.ROEDate,
			'PayPeriodEndingDate'	= tempInsEarn.PayPeriodEndingDate,
			'InsurableEarnings'		= tempInsEarn.InsurableEarnings
		FROM	#tmptableROEInsEarn tempInsEarn


		/* Create sep/special payments temp table to hold records for insert into SSPay history table (vPRROEEmployeeSSPayments) (Blocks 17a, 17b, 17c, 19) */
			/* Each row contains special payment information, or a separation payment, for an ROE for an employee */
			/* Effective composite key is PRCo, Employee, ROEDate, Category, Number; Number exists primarily to guarantee row uniqueness,
			   although it will be output in XML file as "nbr" attribute within SH and OM tags. */

		CREATE TABLE #tmptableROESSPay
		(
			[PRCo]							tinyint			NOT NULL,	--bCompany
			[Employee]						int				NOT NULL,	--bEmployee
			[ROEDate]						smalldatetime	NOT NULL,	--bDate
			[Category]						varchar(2)		NOT NULL,
			[Number]						tinyint			NOT NULL,
			[StatutoryHolidayPaymentDate]	smalldatetime	NULL,		--bDate
			[OtherMoniesCode]				char(1)			NULL,
			[SpecialPaymentStartDate]		smalldatetime	NULL,		--bDate
			[SpecialPaymentCode]			char(3)			NULL,
			[SpecialPaymentPeriod]			char(1)			NULL,
			[Amount]						numeric(12,2)	NOT NULL	--bDollar
		)


		/* Load data into sep/special payments temp table (#tmptableROESSPay) */

		BEGIN TRY
			EXECUTE	dbo.vspPRROEInitializeLoadSSPay
		END TRY
		BEGIN CATCH

			SET @ErrorDetail	= 'Msg ' + CAST(ERROR_NUMBER() AS varchar(50)) + ', '
								  + 'Level ' + CAST(ERROR_SEVERITY() AS varchar(5)) + ', '
								  + 'State ' + CAST(ERROR_STATE() AS varchar(5))  + ', '
								  + 'Procedure ' + ISNULL(ERROR_PROCEDURE(),'-')  + ', '
								  + 'Line ' + CAST(ERROR_LINE() AS varchar(5))

			SET @ErrorMessage	= @ErrorDetail + CHAR(13) + CHAR(10)
								  + CHAR(9) + 'Error encountered in vspPRROEInitializeLoadSSPay: ' + CHAR(13) + CHAR(10)
								  + CHAR(9) + CHAR(9) + ERROR_MESSAGE()

			RAISERROR(@ErrorMessage,16,1)				--Transfers control to outer CATCH block
			
		END CATCH


		/* Insert rows from sep/special payments temp table into SSPay history table (vPRROEEmployeeSSPayments) (Blocks 17a, 17b, 17c, 19) */

		INSERT INTO dbo.vPRROEEmployeeSSPayments
		(
			[PRCo],
			[Employee],
			[ROEDate],
			[Category],
			[Number],
			[StatutoryHolidayPaymentDate],
			[OtherMoniesCode],
			[SpecialPaymentStartDate],
			[SpecialPaymentCode],
			[SpecialPaymentPeriod],
			[Amount]
		)
		SELECT
			'PRCo'							= tempSSPay.PRCo,
			'Employee'						= tempSSPay.Employee,
			'ROEDate'						= tempSSPay.ROEDate,
			'Category'						= tempSSPay.Category,
			'Number'						= tempSSPay.Number,
			'StatutoryHolidayPaymentDate'	= tempSSPay.StatutoryHolidayPaymentDate,
			'OtherMoniesCode'				= tempSSPay.OtherMoniesCode,
			'SpecialPaymentStartDate'		= tempSSPay.SpecialPaymentStartDate,
			'SpecialPaymentCode'			= tempSSPay.SpecialPaymentCode,
			'SpecialPaymentPeriod'			= tempSSPay.SpecialPaymentPeriod,
			'Amount'						= tempSSPay.Amount
		FROM	#tmptableROESSPay tempSSPay


		/* Cleanup: Delete from workfile table (vPRROEEmployeeWorkfile) all and only rows that were processed successfully */

			/* Any processable record in workfile table that failed one or more validation tests, or failed to be inserted successfully
			   into main history table, is now marked by a non-null value in column ValidationTier. (A processable record is any record
			   for the current form company, flagged for processing, and belonging to the current user.) Conversely, any processable
			   record in workfile table that passed all validation tests and was inserted successfully into main history table is now 
			   marked by a null value in column ValidationTier. All such records are considered to have been processed successfully, 
			   and need to be deleted now from workfile table.
			   
			   An equivalent, alternative approach (not used here), would be the following: For each employee whose ROE was inserted 
			   successfully into main history table above, a row exists now in main temp table with an indicator of success 
			   (InsertedHistoryYN = 'Y'). All and only these rows in main temp table were processed further above (resulting in inserts 
			   into InsEarn history table and SSPay history table, if conforming data found for the employee). Each row in main temp table 
			   that was inserted successfully into main history table is considered to have been processed successfully. Each such row in 
			   main temp table corresponds (one-to-one) with a row in workfile table: specifically, each row in main temp table includes 
			   a value (column WorkfileKeyID) that matches a unique identifier in workfile table (column KeyID). Processing code could 
			   delete rows from workfile table whose corresponding rows in main temp table are flagged as having been processed successfully 
			   (InsertedHistoryYN = 'Y'). */

		DELETE
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()		--Processable in workfile table
			AND	ValidationTier IS NULL												--Not invalidated by any validation test or during processing

		--Equivalent, alternative approach
		--	DELETE	Work
		--	FROM	dbo.vPRROEEmployeeWorkfile Work
		--	JOIN	#tmptableROEMain tmpMain ON tmpMain.WorkfileKeyID = Work.KeyID
		--	WHERE	tmpMain.InsertedHistoryYN = 'Y'


		/* Exit: Return appropriate RETURN value and processing summary message */
			/* Check whether any processable records still exist in workfile table. (A processable record is any record for the current 
			   form company, flagged for processing, and belonging to the current user.) Given the above deletion from workfile table of all 
			   and only records that were processed successfully (where ValidationTier is null), any processable record that still exists in 
			   workfile table at this point necessarily has a non-null value in column ValidationTier, indicating failure to validate in 
			   some specific tier or failure to insert into main history table during processing (ValidationTier = 99). In either event, the mere 
			   existence now of at least one processable record in workfile table indicates that not all processable records were processed 
			   successfully. If at least one conforming (invalidated) record exists in workfile table, return 1; if none exists, return 0. 
			   For clarity, test for existence here includes ValidationTier (non-null) as a selection criterion, even though it is unnecessary 
			   and overdeterminate. */

		IF EXISTS
		(
			SELECT	1
			FROM	dbo.vPRROEEmployeeWorkfile
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()		--Processable in workfile table
				AND	ValidationTier IS NOT NULL											--Invalidated by some validation test or during processing
		)
			BEGIN

				SELECT @Msg = 'Some records flagged for processing in grid were not initialized. See Error Messages in grid for data issues that require correction.'

				IF @@TRANCOUNT > 0						--Commit transaction immediately prior to exit (no sooner)
					BEGIN
						COMMIT TRANSACTION tranMain		--Commits all data modifications in all tables
					END

				RETURN 1

			END

		ELSE

			BEGIN

				SELECT @Msg = 'All records flagged for processing in grid were initialized successfully.'

				IF @@TRANCOUNT > 0						--Commit transaction immediately prior to exit (no sooner)
					BEGIN
						COMMIT TRANSACTION tranMain		--Commits all data modifications in all tables
					END

				RETURN 0

			END


	END TRY											--End outer TRY block
	BEGIN CATCH										--Begin outer CATCH block; if system error occurred in outer TRY block, control transferred to outer CATCH block

		IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRANSACTION tranMain		--Roll back transaction prior to any other statement in CATCH block
			END

		SET @ErrorMessage = 'Initialization stopped. No changes committed.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
							+ 'Error encountered in vspPRROEInitializeMain: ' + CHAR(13) + CHAR(10)
							+ CHAR(9) + ERROR_MESSAGE()

		RAISERROR(@ErrorMessage,16,1)
		
		RETURN 1

	END CATCH										--End outer CATCH block


END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEInitializeMain] TO [public]
GO
