SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRROEInitializeVal]

/*****************************************************************************************************************************

Copyright 2013 Viewpoint Construction Software. All rights reserved. 
CREATED BY:		CUC	04/22/13	TFS-39834 PR ROE Electronic File
MODIFIED BY:

INPUT PARAMETERS
 @PRCo               PR Company

OUTPUT PARAMETERS
 none

RETURN VALUES
 none

USAGE
This is a secondary (helper) procedure used in the PR module to initialize the Record of Employment (Canada). This procedure 
is called by the primary procedure (vspPRROEInitializeMain).

This procedure validates data required for initialization. Specifically, this procedure updates the validation columns 
(ValidationTier; ErrorMessage) in the ROE workfile table (vPRROEEmployeeWorkfile) for any processable workfile input record 
that fails one or more validation tests. ValidationTier is a process control column; the ErrorMessage column is used for 
messages to the user detailing data issues that require correction.

See inline comments within procedure for full details. See also the general overview of ROE initialization processing in the 
opening flowerbox comments within the primary procedure (vspPRROEInitializeMain).

*****************************************************************************************************************************/

(
	@PRCo	bCompany
)

AS

BEGIN

	SET NOCOUNT ON

	/* Validate data required for processing */
		/* Validation is attempted on all processable records in the workfile table. A processable record is any record
		   for the current form company, flagged for processing, and belonging to the current user. Validation tests are
		   performed in groups called "tiers". For any workfile grid record that fails validation in some tier, no validation
		   tests from any subsequent tier are attempted, and all errors are reported from all tests within the tier where
		   the failure occurred. Validation tests are ordered so that more general or fundamental tests appear in earlier
		   tiers, and more specific or superficial tests appear in later tiers. Additionally, tests are ordered and grouped
		   in tiers such that only one error message appears for any given data deficiency; cascading errors are avoided
		   by design. */


	/* Validate input data - Initialize validation columns to NULL for rows currently being processed */

	UPDATE	dbo.vPRROEEmployeeWorkfile
	SET		ValidationTier = NULL, ErrorMessage = NULL
	WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()					--Processable in workfile table


	/* Validate input data - Tier 1: reject workfile grid records that represent duplicates on employee */

	UPDATE	Work1
	SET		Work1.ValidationTier = 1, Work1.ErrorMessage = 'Multiple records exist in grid for this Employee'
	FROM	dbo.vPRROEEmployeeWorkfile Work1
	JOIN
	(
			SELECT	Work2.PRCo, Work2.Employee, Work2.VPUserName
			FROM	dbo.vPRROEEmployeeWorkfile Work2
			WHERE	Work2.PRCo = @PRCo AND Work2.ProcessYN = 'Y' AND Work2.VPUserName = SUSER_SNAME()
			GROUP BY Work2.PRCo, Work2.Employee, Work2.VPUserName
			HAVING COUNT(Work2.PRCo) > 1														--Duplication within workfile table on PRCo, Employee, VPUserName
	) Dupe
			ON Dupe.PRCo = Work1.PRCo AND Dupe.Employee = Work1.Employee AND Dupe.VPUserName = Work1.VPUserName
	WHERE	Work1.PRCo = @PRCo AND Work1.ProcessYN = 'Y' AND Work1.VPUserName = SUSER_SNAME()	--Processable in workfile table
		AND Work1.ValidationTier IS NULL														--Not invalidated in any prior tier


	/* Validate input data - Tier 2: reject any workfile grid record that lacks required values (or has non-allowed values) in specific fields in grid */

	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN


			--Test for missing value in required grid field Employee
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage = 'Required value(s) missing in grid: Employee'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND ValidationTier IS NULL											--Not invalidated in any prior tier
				AND (Employee IS NULL OR Employee = 0)								--Missing value: Employee


			--Test for missing value in required grid field ROE Date
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'ROE Date'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ROEDate IS NULL OR ROEDate = '')								--Missing value: ROE Date


			--Test for missing value in required grid field Reason for ROE
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Reason for ROE'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() 
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ReasonForROE IS NULL OR ReasonForROE = '')						--Missing value: Reason for ROE


			--Test for missing value in required grid field Contact First Name
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Contact First Name'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ContactFirstName IS NULL OR ContactFirstName = '')				--Missing value: Contact First Name


			--Test for missing value in required grid field Contact Last Name
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Contact Last Name'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ContactLastName IS NULL OR ContactLastName = '')				--Missing value: Contact Last Name


			--Test for missing value in required grid field Contact Area Code
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Contact Area Code'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ContactAreaCode IS NULL OR ContactAreaCode = '')				--Missing value: Contact Area Code


			--Test for missing value in required grid field Contact Phone
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Contact Phone'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ContactPhoneNbr IS NULL OR ContactPhoneNbr = '')				--Missing value: Contact Phone


			--Test for missing value in conditionally-required grid field Recall Date (required when Recall Code is 'Y-Date of Recall')
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Recall Date (required when Recall Code is ''Y-Date of Recall'')'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (ExpectedRecallDate IS NULL OR ExpectedRecallDate = '')			--Missing value: Recall Date (required when Recall Code is 'Y-Date of Recall')
				AND ExpectedRecallCode = 'Y'


			--Test for missing value in conditionally-required grid field Comments (required when Reason for ROE is 'K-Other')
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in grid: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Comments (required when Reason for ROE is ''K-Other'')'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND (Comments IS NULL OR Comments = '')								--Missing value: Comments (required when Reason for ROE is 'K-Other')
				AND ReasonForROE = 'K'


			--Test for non-allowed value in required grid field Reason for ROE (note that existence of value confirmed by prior Tier 2 test)
			--Null and blank are included in list of allowed values in order to avoid cascading error message following prior Tier 2 test for existence
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Reason for ROE value in grid other than ''A'',''B'',''C'',''D'',''E'',''F'',''G'',''H'',''J'',''K'',''M'',''N'',''P'', or ''Z'''
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND NOT (ReasonForROE IS NULL OR ReasonForROE = '' OR ReasonForROE IN ('A','B','C','D','E','F','G','H','J','K','M','N','P','Z'))	--Non-allowed value: Reason for ROE


			--Test for non-allowed value in optional grid field Recall Code
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Recall Code value in grid other than ''Y'', ''N'', ''U'', or ''S'''
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND NOT (ExpectedRecallCode IS NULL OR ExpectedRecallCode = '' OR ExpectedRecallCode IN ('Y','N','U','S'))	--Non-allowed value: Recall Code
				

			--Test for existing value in grid field Recall Date (must be blank when Reason for ROE is 'E', 'G', or 'M')
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Recall Date value exists in grid (must be blank when Reason for ROE is ''E'', ''G'', or ''M'')'
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND NOT (ExpectedRecallDate IS NULL OR ExpectedRecallDate = '')		--Existing value: Recall Date (must be blank when Reason for ROE is 'E', 'G', or 'M')
				AND ReasonForROE IN ('E','G','M')


			--Test for non-allowed value in optional grid field Language
			UPDATE	dbo.vPRROEEmployeeWorkfile
			SET		ValidationTier = 2, 
					ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Language value in grid other than ''E'' or ''F'''
			WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME()
				AND (ValidationTier IS NULL OR ValidationTier = 2)
				AND NOT ([Language] IS NULL OR [Language] = '' OR [Language] IN ('E','F'))	--Non-allowed value: Language

		END


	/* Validate input data - Tier 3: reject any workfile grid record that matches pre-existing record in history table in some specific way */
		
	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN

			--Test for pre-existing record in history table matching on PR Company, Employee, ROEDate		
			UPDATE	Work
			SET		Work.ValidationTier = 3,
					Work.ErrorMessage = 'Record already exists in PR Record of Employment for this PR Company, Employee, ROEDate'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.vPRROEEmployeeHistory Hist ON Hist.PRCo = Work.PRCo AND Hist.Employee = Work.Employee AND Hist.ROEDate = Work.ROEDate
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier


			--Test for pre-existing record in history table matching on PR Company, Employee, First Day Worked, Last Day Paid
			UPDATE	Work
			SET		Work.ValidationTier = 3,
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Record already exists in PR Record of Employment for this PR Company, Employee, First Day Worked, Last Day Paid'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			JOIN	dbo.vPRROEEmployeeHistory Hist ON Hist.PRCo = Emp.PRCo AND Hist.Employee = Emp.Employee AND Hist.FirstDayWorked = Emp.RecentRehireDate AND Hist.LastDayPaid = Emp.RecentSeparationDate
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 3)

		END


	/* Validate input data - Tier 4: reject any workfile grid record that lacks required values (or has non-allowed values) in other related tables (bPREH) */
		
	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN

			--Test for missing record in related table PR Employees
			--This test is designed to be mutually exclusive with all other tests in this tier; in other words:
			--If this error condition exists, then (as desired) all other tests in this tier will fail to run (due to JOIN), preventing cascading error messages
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage = 'Employee record missing in PR Employees'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			LEFT JOIN dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee		--Left join allows for non-existence in PR Employees
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier
				AND	Emp.Employee IS NULL															--Employee record missing altogether from PR Employees


			--Test for missing value in related table PR Employees: SIN (SSN)
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage = 'Required value(s) missing in PR Employees: SIN'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee			--Join requires existence in PR Employees
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier
				AND	(Emp.SSN IS NULL OR Emp.SSN = '')												--Missing value in related table: SIN (SSN)


			--Test for missing value in related table PR Employees: First Name
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'First Name'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.FirstName IS NULL OR Emp.FirstName = '')									--Missing value in related table: First Name


			--Test for missing value in related table PR Employees: Last Name
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Last Name'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.LastName IS NULL OR Emp.LastName = '')										--Missing value in related table: Last Name


			--Test for missing value in related table PR Employees: Address
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Address'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.[Address] IS NULL OR Emp.[Address] = '')									--Missing value in related table: Address


			--Test for missing value in related table PR Employees: Most Recent Rehire Date
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Most Recent Rehire Date'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.RecentRehireDate IS NULL OR Emp.RecentRehireDate = '')						--Missing value in related table: Most Recent Rehire Date


			--Test for missing value in related table PR Employees: Most Recent Separation Date
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'Most Recent Separation Date'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.RecentSeparationDate IS NULL OR Emp.RecentSeparationDate = '')				--Missing value in related table: Most Recent Separation Date


			--Test for missing value in related table PR Employees: PR Group
			UPDATE	Work
			SET		Work.ValidationTier = 4, 
					Work.ErrorMessage =
					(
						CASE
							WHEN ErrorMessage IS NULL THEN 'Required value(s) missing in PR Employees: '
							ELSE ErrorMessage + ', ' END
					)
						+ 'PR Group'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)
				AND	(Emp.PRGroup IS NULL)															--Missing value in related table: PR Group
																									--Cannot test for PRGroup = 0 because 0 is allowed value

			--Test for non-allowed value in related table PR Employees: SIN (SSN)
			UPDATE	Work
			SET		Work.ValidationTier = 4,
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'SIN value in PR Employees begins with ''0'' or ''8'''
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 4)						--Not invalidated in any prior tier
				AND	LEFT(Emp.SSN,1) IN ('0','8')													--Non-allowed value in related table: SIN (SSN)

		END


	/* Validate input data - Tier 5: reject any workfile grid record that lacks required values (or has non-allowed values) in other related tables (bPRGR) */
		
	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN

			--Test for missing record in related table PR Group Master
			--This test is designed to be mutually exclusive with all other tests in this tier; in other words:
			--If this error condition exists, then (as desired) all other tests in this tier will fail to run (due to JOIN), preventing cascading error messages
			UPDATE	Work
			SET		Work.ValidationTier = 5, 
					Work.ErrorMessage = 'Payroll Group record missing in PR Group Master'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			LEFT JOIN dbo.bPRGR Grp	ON Grp.PRCo = Emp.PRCo AND Grp.PRGroup = Emp.PRGroup			--Left join allows for non-existence in PR Group Master
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier
				AND	Grp.PRGroup IS NULL																--Payroll Group record missing altogether from PR Group Master


			--Test for missing value in related table PR Group Master: Pay Period (PayFreq)
			UPDATE	Work
			SET		Work.ValidationTier = 5, 
					Work.ErrorMessage = 'Required value(s) missing in PR Group Master: Pay Period (PayFreq)'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			JOIN	dbo.bPRGR Grp ON Grp.PRCo = Emp.PRCo AND Grp.PRGroup = Emp.PRGroup				--Join requires existence in PR Group Master
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier
				AND	(Grp.PayFreq IS NULL OR Grp.PayFreq = '')										--Missing value in related table: Pay Period (PayFreq)


			--Test for non-allowed value in related table PR Group Master: Pay Period (PayFreq) (note that existence of value confirmed by prior Tier 5 test)
			--Null and blank are included in list of allowed values in order to avoid cascading error message following prior Tier 5 test for existence
			--Practically speaking, this test is mutually exclusive with both prior tests in Tier 5 (thus accommodations in SET and WHERE clauses are gratuitous)
			UPDATE	Work
			SET		Work.ValidationTier = 5, 
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Pay Period (PayFreq) value in PR Group Master other than ''W'',''B'',''S'', or ''M'''
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			JOIN	dbo.bPRGR Grp ON Grp.PRCo = Emp.PRCo AND Grp.PRGroup = Emp.PRGroup
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 5)
				AND	NOT (Grp.PayFreq IS NULL OR Grp.PayFreq = '' OR Grp.PayFreq IN ('W','B','S','M'))	--Non-allowed value in related table: Pay Period (PayFreq)

		END


	/* Validate input data - Tier 6: reject any workfile grid record for which required record is missing (or has non-allowed values) in other related table (bPRPC) */
		
	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN

			--Test for missing final pay period record in related table PR Pay Period Control
			--This test is designed to be mutually exclusive with all other tests in this tier; in other words:
			--If this error condition exists, then (as desired) all other tests in this tier will fail to run (due to JOIN), preventing cascading error messages
			UPDATE	Work
			SET		Work.ValidationTier = 6, 
					Work.ErrorMessage = 'Final pay period missing in PR Pay Period Control: '
						+ 'For this employee''s payroll group, no pay period exists that includes this employee''s Most Recent Separation Date'		
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			LEFT JOIN dbo.bPRPC PayPrd ON PayPrd.PRCo = Emp.PRCo AND PayPrd.PRGroup = Emp.PRGroup				--Left join allows for non-existence in PR Pay Period Control
								AND (Emp.RecentSeparationDate BETWEEN PayPrd.BeginDate AND PayPrd.PREndDate)	--Pay period includes employee's Most Recent Separation Date
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()				--Processable in workfile table
				AND Work.ValidationTier IS NULL																	--Not invalidated in any prior tier
				AND PayPrd.PREndDate IS NULL																	--Pay period record missing altogether from Pay Period Control


			--Test for non-allowed value in related table PR Pay Period Control (namely, final pay period ending date outside of allowed range)
			--Final pay period ending date may not be more than X days after employee's separation date (Last Day for Which Paid); X varies by pay period frequency (PayFreq)
			--When PayFreq is 'W', then X = 6; when PayFreq is 'B', then X = 13; when PayFreq is 'S', then X = 15; when PayFreq is 'M', then X = 30.
			UPDATE	Work
			SET		Work.ValidationTier = 6, 
					Work.ErrorMessage = 'With Pay Period (PayFreq) ''' + Grp.PayFreq + ''' in PR Group Master, final pay period ending date in PR Pay Period Control more than ' + 
					(
						CASE Grp.PayFreq
							WHEN 'W' THEN '6'
							WHEN 'B' THEN '13'
							WHEN 'S' THEN '15'
							WHEN 'M' THEN '30' END
					)	+ ' days after employee''s Most Recent Separation Date'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			JOIN	dbo.bPRGR Grp ON Grp.PRCo = Emp.PRCo AND Grp.PRGroup = Emp.PRGroup
			JOIN
			(
					SELECT	PayPrd.PRCo, PayPrd.PRGroup, MIN(PayPrd.PREndDate) AS PREndDate								--PREndDate that follows Separation Date most closely is "final" one
					FROM	dbo.vPRROEEmployeeWorkfile Work
					JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
					JOIN	dbo.bPRPC PayPrd ON PayPrd.PRCo = Emp.PRCo AND PayPrd.PRGroup = Emp.PRGroup					--Join requires existence in PR Pay Period Control
										AND (Emp.RecentSeparationDate BETWEEN PayPrd.BeginDate AND PayPrd.PREndDate)	--Pay period includes employee's Most Recent Separation Date
					WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()				--Processable in workfile table
						AND Work.ValidationTier IS NULL																	--Not invalidated in any prior tier
					GROUP BY PayPrd.PRCo, PayPrd.PRGroup
			)	FinalPayPrd
					ON FinalPayPrd.PRCo = Grp.PRCo AND FinalPayPrd.PRGroup = Grp.PRGroup
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()						--Processable in workfile table
				AND Work.ValidationTier IS NULL																			--Not invalidated in any prior tier
				AND	FinalPayPrd.PREndDate >																				--Error condition: final PREndDate more than X days after Separation Date
				(
					CASE Grp.PayFreq
						WHEN 'W' THEN DATEADD(day,06,Emp.RecentSeparationDate)											--If weekly, then X = 6 (days)
						WHEN 'B' THEN DATEADD(day,13,Emp.RecentSeparationDate)											--If bi-weekly, then X = 13 (days)
						WHEN 'S' THEN DATEADD(day,15,Emp.RecentSeparationDate)											--If semi-monthly, then X = 15 (days)
						WHEN 'M' THEN DATEADD(day,30,Emp.RecentSeparationDate) END										--If monthly, then X = 30 (days)
				)

		END


	/* Validate input data - Tier 7: reject any workfile grid record for which date fields in grid and in other related tables compare improperly to one another */
		
	IF EXISTS  --Proceed to this tier only if there is at least one processable record that did not fail validation in some prior tier
	(
		SELECT	1
		FROM	dbo.vPRROEEmployeeWorkfile
		WHERE	PRCo = @PRCo AND ProcessYN = 'Y' AND VPUserName = SUSER_SNAME() AND ValidationTier IS NULL
	)
		BEGIN

			--Test for error condition: rehire date is not earlier than or equal to separation date
			UPDATE	Work
			SET		Work.ValidationTier = 7,
					Work.ErrorMessage = 'Employee''s Most Recent Rehire Date in PR Employees not earlier than or equal to Most Recent Separation Date'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND Work.ValidationTier IS NULL														--Not invalidated in any prior tier
				AND	NOT (Emp.RecentRehireDate <= Emp.RecentSeparationDate)							--Recent Rehire Date not earlier than or equal to Recent Separation Date


			--Test for error condition: rehire date is not earlier than or equal to final pay period ending date

				/* This test is covered by a combination of the first test in present Tier 7 (where a pass confirms that rehire date 
				   is earlier than or equal to separation date) and prior Tier 6 (where a pass confirms that separation date is earlier 
				   than or equal to final pay period ending date). If a record passes the first test in present Tier 7, then it would 
				   necessarily also pass this second test; if the record fails the first test in present Tier 7, then it may or may not 
				   also fail this second test, but the point is moot, for the user will be required to correct the record so that it passes 
				   the first test in present Tier 7, which by inference would constitute a pass of this second test. Additionally, 
				   refraining from exercising this second (redundant) test allows us to avoid the possibility of multiple (cascading) 
				   error messages from what may be considered a single error condition. */


			--Test for error condition: separation date is not earlier than or equal to final pay period ending date

				/* This test is covered by prior Tier 6 as a necessary part of testing for missing final pay period record */


			--Test for error condition: recall date in workfile grid, if exists, is not later than separation date
			UPDATE	Work
			SET		Work.ValidationTier = 7,
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Recall Date in grid not later than employee''s Most Recent Separation Date in PR Employees'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 7)						--Not invalidated in any prior tier
				AND	NOT (Work.ExpectedRecallDate IS NULL OR Work.ExpectedRecallDate = '' OR Work.ExpectedRecallDate > Emp.RecentSeparationDate)
																									--Recall Date exists and is not later than Recent Separation Date

			--Test for error condition: special payment start date in workfile grid, if exists, is not later than or equal to rehire date
			UPDATE	Work
			SET		Work.ValidationTier = 7,
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Special Payment Start Date in grid not later than or equal to employee''s Most Recent Rehire Date in PR Employees'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 7)						--Not invalidated in any prior tier
				AND	NOT (Work.SpecialPaymentsStartDate IS NULL OR Work.SpecialPaymentsStartDate = '' OR Work.SpecialPaymentsStartDate >= Emp.RecentRehireDate)
																									--SP Start Date exists and is not later than or equal to Recent Rehire Date

			--Test for error condition: special payment start date in workfile grid, if exists, is not earlier than or equal to separation date
			UPDATE	Work
			SET		Work.ValidationTier = 7,
					Work.ErrorMessage =
						(CASE WHEN ErrorMessage IS NOT NULL THEN ErrorMessage + '; ' ELSE '' END)
						+ 'Special Payment Start Date in grid not earlier than or equal to employee''s Most Recent Separation Date in PR Employees'
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()	--Processable in workfile table
				AND (Work.ValidationTier IS NULL OR Work.ValidationTier = 7)						--Not invalidated in any prior tier
				AND	NOT (Work.SpecialPaymentsStartDate IS NULL OR Work.SpecialPaymentsStartDate = '' OR Work.SpecialPaymentsStartDate <= Emp.RecentSeparationDate)
																									--SP Start Date exists and is not earlier than or equal to Recent Separation Date
		END


END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEInitializeVal] TO [public]
GO
