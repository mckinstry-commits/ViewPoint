SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRROEInitializeLoadSSPay]

/*****************************************************************************************************************************

Copyright 2013 Viewpoint Construction Software. All rights reserved. 
CREATED BY:		CUC	04/22/13	TFS-39834 PR ROE Electronic File
MODIFIED BY:

INPUT PARAMETERS
 none

OUTPUT PARAMETERS
 none

RETURN VALUES
 none

USAGE
This is a secondary (helper) procedure used in the PR module to initialize the Record of Employment (Canada). This procedure 
is called by the primary procedure (vspPRROEInitializeMain).

This procedure assembles the record set that is later inserted into the SSPay history table (vPRROEEmployeeSSPayments).
(Each row in the SSPay history table contains special payment information, or a separation payment, for an ROE for an 
employee.) Specifically, this procedure inserts rows (iteratively) into the sep/special payments temp table (#tmptableROESSPay), 
using the pay sequence totals table (bPRDT) and the timecard header table (bPRTH), variously, as primary data sources.

See inline comments within procedure for full details. See also the general overview of ROE initialization processing in the 
opening flowerbox comments within the primary procedure (vspPRROEInitializeMain).

*****************************************************************************************************************************/

AS

BEGIN

	SET NOCOUNT ON

	/* Raise error and exit if sep/special payments temp table (#tmptableROESSPay) does not exist */

	IF OBJECT_ID('tempdb..#tmptableROESSPay') IS NULL
		BEGIN

			DECLARE @ErrorMessage varchar(255)
			SET		@ErrorMessage = 'Temp table #tmptableROESSPay, required by procedure vspPRROEInitializeLoadSSPay, does not exist. ' + CHAR(13) + CHAR(10)
									+ 'This procedure is intended to be called from vspPRROEInitializeMain, where that temp table is defined.'

			RAISERROR(@ErrorMessage,16,1)

			RETURN 1

		END


	/* Insert rows (primarily from pay sequence totals table bPRDT) into sep/special payments temp table for Block 17a */
		/* Block 17a is for separation payments of category 'V-Vacation' */

		/* For each employee whose ROE was inserted successfully into main history table above, a row exists now in main temp table 
		   with an indicator of success (InsertedHistoryYN = 'Y'). All and only these rows in main temp table should be processed further. 
		   For each such row: For each employee for whom one or more vacation separation payments exist within the employee's 
		   "limited" period of employment (defined as the set of pay periods between initial pay period end date for Block 15a and 
		   final pay period end date, inclusive of end points), load exactly one row into sep/special payments temp table containing 
		   a single dollar amount representing the sum of earnings (in bPRDT) from all earncodes that are designated in bPREC as 
		   "Separation" and "V-Vacation" (without regard for whether any given earncode is or is not designated in bPREC as 
		   "insurable earnings"); include amounts only if related employee pay sequence in bPRSQ has been processed; no more than 
		   one row may be loaded per PRCo, Employee, ROEDate (effectively, per PRCo, Employee, since that combination is unique 
		   in main temp table). If an employee has no conforming vacation separation payments, load no row for that employee. */

	INSERT INTO #tmptableROESSPay
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
		'PRCo'							= tmpMain.PRCo,
		'Employee'						= tmpMain.Employee,
		'ROEDate'						= tmpMain.ROEDate,
		'Category'						= EarnCd.ROECategory,
		'Number'						= 1,			--Constant permissible because grouping below guarantees no more than one row per PRCo, Employee (as required)
		'StatutoryHolidayPaymentDate'	= NULL,
		'OtherMoniesCode'				= NULL,
		'SpecialPaymentStartDate'		= NULL,
		'SpecialPaymentCode'			= NULL,
		'SpecialPaymentPeriod'			= NULL,
		'Amount'						= SUM(PaySeqDetail.Amount)
	FROM	#tmptableROEMain tmpMain
	JOIN	dbo.bPRDT PaySeqDetail
				ON PaySeqDetail.PRCo = tmpMain.PRCo
				AND PaySeqDetail.PRGroup = tmpMain.PRGroup
				AND PaySeqDetail.Employee = tmpMain.Employee
				AND PaySeqDetail.PREndDate BETWEEN tmpMain.InitialPayPeriodEndDate15a AND tmpMain.FinalPayPeriodEndDate
	JOIN	dbo.bPREC EarnCd
				ON EarnCd.PRCo = PaySeqDetail.PRCo
				AND EarnCd.EarnCode = PaySeqDetail.EDLCode
	JOIN	dbo.bPRSQ PaySeq
				ON PaySeq.PRCo = PaySeqDetail.PRCo
				AND PaySeq.PRGroup = PaySeqDetail.PRGroup
				AND PaySeq.PREndDate = PaySeqDetail.PREndDate
				AND PaySeq.Employee = PaySeqDetail.Employee
				AND PaySeq.PaySeq = PaySeqDetail.PaySeq
	WHERE	tmpMain.InsertedHistoryYN = 'Y'				--Process only main temp table rows previously inserted into main history table successfully
		AND PaySeqDetail.EDLType = 'E'					--Earnings
		AND	EarnCd.ROESeparationYN = 'Y'				--Earncode flagged for separation payment
		AND EarnCd.ROECategory = 'V'					--Earncode designated for separation payment category 'V' (vacation)
		AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
	GROUP BY tmpMain.PRCo, tmpMain.Employee, tmpMain.ROEDate, EarnCd.ROECategory	--Effectively grouped by PRCo, Employee only (as a result of validation)


	/* Insert rows (primarily from timecard header table bPRTH) into sep/special payments temp table for Block 17b */
		/* Block 17b is for separation payments of category 'SH-Statutory Holiday' */

		/* For each employee whose ROE was inserted successfully into main history table above, a row exists now in main temp table 
		   with an indicator of success (InsertedHistoryYN = 'Y'). All and only these rows in main temp table should be processed further. 
		   For each such row: For each employee for whom one or more statutory holiday separation payments exist within the employee's 
		   "limited" period of employment (defined as the set of pay periods between initial pay period end date for Block 15a and 
		   final pay period end date, inclusive of end points) whose holiday date (bPRTH.PostDate) falls after the employee's 
		   recent separation date, load one row for each such conforming statutory holiday payment into sep/special payments 
		   temp table; each row represents a single timecard payment (date and amount) from bPRTH for an earncode that is designated 
		   in bPREC as "Separation" and "SH-Statutory Holiday" (without regard for whether the earncode is or is not designated in bPREC 
		   as "insurable earnings"); include only statutory holiday payments whose post date falls after the employee's recent separation date;
		   include amounts only if related employee pay sequence in bPRSQ has been processed. Load at most three statutory holiday 
		   payments per PRCo, Employee, ROEDate (effectively, per PRCo, Employee, since that combination is unique in main temp table); 
		   if more than three conforming payments exist for an employee, load only the top three in order of post date ascending; 
		   assign a unique Number value to each payment in order of post date ascending. If an employee has no conforming statutory 
		   holiday separation payments, load no rows for that employee. */

	INSERT INTO #tmptableROESSPay
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
		'PRCo'							= tmpMain1.PRCo,
		'Employee'						= tmpMain1.Employee,
		'ROEDate'						= tmpMain1.ROEDate,
		'Category'						= TopStatHolPaymtsByEmp.ROECategory,
		'Number'						= TopStatHolPaymtsByEmp.Number,
		'StatutoryHolidayPaymentDate'	= TopStatHolPaymtsByEmp.PostDate,
		'OtherMoniesCode'				= NULL,
		'SpecialPaymentStartDate'		= NULL,
		'SpecialPaymentCode'			= NULL,
		'SpecialPaymentPeriod'			= NULL,
		'Amount'						= TopStatHolPaymtsByEmp.Amt
	FROM	#tmptableROEMain tmpMain1
	CROSS APPLY
	(
			SELECT TOP(3)	StatHolPaymtsByEmp.PRCo,					--Limit to top three payments (per PRCo, Employee) ordered by post date ascending
							StatHolPaymtsByEmp.Employee,
							StatHolPaymtsByEmp.ROECategory,
							ROW_NUMBER() OVER (PARTITION BY StatHolPaymtsByEmp.PRCo, StatHolPaymtsByEmp.Employee ORDER BY StatHolPaymtsByEmp.PostDate) AS Number,
							StatHolPaymtsByEmp.PostDate,
							StatHolPaymtsByEmp.Amt
			FROM
			(
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, EarnCd.ROECategory, Timecard.PostDate, Timecard.Amt
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRTH Timecard
								ON Timecard.PRCo = tmpMain2.PRCo
								AND Timecard.PRGroup = tmpMain2.PRGroup
								AND Timecard.Employee = tmpMain2.Employee
								AND Timecard.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15a AND tmpMain2.FinalPayPeriodEndDate
					JOIN	dbo.bPREC EarnCd
								ON EarnCd.PRCo = Timecard.PRCo
								AND EarnCd.EarnCode = Timecard.EarnCode
					JOIN	dbo.bPRSQ PaySeq
								ON PaySeq.PRCo = Timecard.PRCo
								AND PaySeq.PRGroup = Timecard.PRGroup
								AND PaySeq.PREndDate = Timecard.PREndDate
								AND PaySeq.Employee = Timecard.Employee
								AND PaySeq.PaySeq = Timecard.PaySeq
					WHERE	tmpMain2.InsertedHistoryYN = 'Y'			--Process only main temp table rows previously inserted into main history table successfully
						AND	EarnCd.ROESeparationYN = 'Y'				--Earncode flagged for separation payment
						AND EarnCd.ROECategory = 'SH'					--Earncode designated for separation payment category 'SH' (statutory holiday)
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
						AND	Timecard.PostDate > tmpMain2.LastDayPaid	--Holiday date later than employee's recent separation date
			)	StatHolPaymtsByEmp										--Statutory holiday payments by PRCo, Employee
			WHERE	StatHolPaymtsByEmp.PRCo = tmpMain1.PRCo				--Criteria for APPLY operator
				AND StatHolPaymtsByEmp.Employee = tmpMain1.Employee
			ORDER BY StatHolPaymtsByEmp.PRCo, StatHolPaymtsByEmp.Employee, StatHolPaymtsByEmp.PostDate
	)	TopStatHolPaymtsByEmp											--Statutory holiday payments by PRCo, Employee, limited to top three ordered by post date ascending


	/* Insert rows (primarily from pay sequence totals table bPRDT) into sep/special payments temp table for Block 17c */
		/* Block 17c is for separation payments of category 'OM-Other Monies' */

		/* For each employee whose ROE was inserted successfully into main history table above, a row exists now in main temp table 
		   with an indicator of success (InsertedHistoryYN = 'Y'). All and only these rows in main temp table should be processed further. 
		   For each such row: For each employee for whom one or more other monies separation payments exist within the employee's 
		   "limited" period of employment (defined as the set of pay periods between initial pay period end date for Block 15a and 
		   final pay period end date, inclusive of end points), load no more than three rows into sep/special payments temp table, 
		   each row containing a single dollar amount representing the sum of earnings (in bPRDT) from all earn codes that are 
		   designated in bPREC as "Separation" and "OM-Other Monies" of a particular Other Monies Type (e.g., "A" or "B" or "E", etc.); 
		   in other words, each row represents the sum of earnings for a single Other Monies Type (which may be represented by 
		   multiple earncodes); include amounts without regard for whether any given earncode is or is not designated in bPREC 
		   as "insurable earnings"; include amounts only if related employee pay sequence in bPRSQ has been processed. Load at most 
		   three rows (i.e., one sum for each of three distinct Other Monies Types) per PRCo, Employee, ROEDate (effectively, 
		   per PRCo, Employee, since that combination is unique in main temp table); if more than three conforming sums 
		   (i.e., three distinct Other Monies Types) exist for an employee, load only the top three in order of sum (amount) descending, 
		   type ascending (i.e., first, the largest sum; second, the second-largest sum; etc.; if two or more sums are identical, 
		   first the one with the least Other Monies Type Code; etc.); assign a unique Number value to each row (sum) in order of 
		   sum (amount) descending, type ascending. If an employee has no conforming other monies separation payments, load no rows 
		   for that employee. */

	INSERT INTO #tmptableROESSPay
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
		'PRCo'							= tmpMain1.PRCo,
		'Employee'						= tmpMain1.Employee,
		'ROEDate'						= tmpMain1.ROEDate,
		'Category'						= TopOtherMoniesByType.ROECategory,
		'Number'						= TopOtherMoniesByType.Number,
		'StatutoryHolidayPaymentDate'	= NULL,
		'OtherMoniesCode'				= TopOtherMoniesByType.OtherMonies,
		'SpecialPaymentStartDate'		= NULL,
		'SpecialPaymentCode'			= NULL,
		'SpecialPaymentPeriod'			= NULL,
		'Amount'						= TopOtherMoniesByType.Amount
	FROM	#tmptableROEMain tmpMain1
	CROSS APPLY
	(
			SELECT TOP(3)	OtherMoniesByType.PRCo,						--Limit to top three sums (per PRCo, Employee) ordered by amount descending, type ascending
							OtherMoniesByType.Employee,
							OtherMoniesByType.ROECategory,
							ROW_NUMBER() OVER
								(
									PARTITION BY OtherMoniesByType.PRCo, OtherMoniesByType.Employee 
									ORDER BY OtherMoniesByType.Amount DESC, OtherMoniesByType.OtherMonies
								) AS Number,
							OtherMoniesByType.OtherMonies,
							OtherMoniesByType.Amount
			FROM
			(
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, EarnCd.ROECategory, EarnCd.OtherMonies, SUM(PaySeqDetail.Amount) AS Amount
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRDT PaySeqDetail
								ON PaySeqDetail.PRCo = tmpMain2.PRCo
								AND PaySeqDetail.PRGroup = tmpMain2.PRGroup
								AND PaySeqDetail.Employee = tmpMain2.Employee
								AND PaySeqDetail.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15a AND tmpMain2.FinalPayPeriodEndDate
					JOIN	dbo.bPREC EarnCd
								ON EarnCd.PRCo = PaySeqDetail.PRCo
								AND EarnCd.EarnCode = PaySeqDetail.EDLCode
					JOIN	dbo.bPRSQ PaySeq
								ON PaySeq.PRCo = PaySeqDetail.PRCo
								AND PaySeq.PRGroup = PaySeqDetail.PRGroup
								AND PaySeq.PREndDate = PaySeqDetail.PREndDate
								AND PaySeq.Employee = PaySeqDetail.Employee
								AND PaySeq.PaySeq = PaySeqDetail.PaySeq
					WHERE	tmpMain2.InsertedHistoryYN = 'Y'			--Process only main temp table rows previously inserted into main history table successfully
						AND PaySeqDetail.EDLType = 'E'					--Earnings
						AND	EarnCd.ROESeparationYN = 'Y'				--Earncode flagged for separation payment
						AND EarnCd.ROECategory = 'OM'					--Earncode designated for separation payment category 'OM' (other monies)
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
					GROUP BY	tmpMain2.PRCo,							--Effectively grouped by PRCo, Employee, Type (EarnCd.OtherMonies) only
								tmpMain2.Employee, 
								EarnCd.ROECategory, 
								EarnCd.OtherMonies
			)	OtherMoniesByType										--Other monies separation payment sums by PRCo, Employee, Type (EarnCd.OtherMonies)
			WHERE	OtherMoniesByType.PRCo = tmpMain1.PRCo				--Criteria for APPLY operator
				AND OtherMoniesByType.Employee = tmpMain1.Employee
			ORDER BY OtherMoniesByType.PRCo, OtherMoniesByType.Employee, OtherMoniesByType.Amount DESC, OtherMoniesByType.OtherMonies
	)	TopOtherMoniesByType	--Other monies sums by PRCo, Employee, Type (EarnCd.OtherMonies), limited to top three ordered by amount descending, type ascending


	/* Insert rows (primarily from timecard header table bPRTH) into sep/special payments temp table for Block 19 */
		/* Block 19 is for special payments (type PSL: paid sick leave; type MAT: maternity or care leave; type WLI: wage-loss indemnity) */

		/* For each employee whose ROE was inserted successfully into main history table above, a row exists now in main temp table 
		   with an indicator of success (InsertedHistoryYN = 'Y'). All and only these rows in main temp table should be processed further. 
		   For each such row: For each employee for whom a special payment start date was specified in workfile grid (now in main 
		   temp table) and for whom one or more insurable special payments exist within a specially-defined time period for the employee
		   (namely, the employee's "limited" period of employment (defined as the set of pay periods between initial pay period end date 
		   for Block 15a and final pay period end date, inclusive of end points), further restricted with respect to timecard post dates
		   to the time period between special payment start date and last day for which paid (recent separation date), inclusive 
		   of end points), load exactly one row into sep/special payments temp table containing a single dollar amount representing 
		   the average posted payment amount (average timecard row amount in bPRTH) within the relevant time period for a single 
		   earn code that is designated in bPREC as "Special" and as "insurable earnings"; include payment (timecard row) in evaluation 
		   only if related employee pay sequence in bPRSQ has been processed. If an employee has no special payment start date 
		   in workfile grid, or has no conforming special payments, load no row for that employee.
		   
		   Per Service Canada instructions, intended usage is that the employer will issue the ROE only after special payments to 
		   the employee -- of one specific type -- have been exhausted. (Only one special payment type (PSL or MAT or WLI) may be 
		   reported on a given ROE, per Service Canada.) Our intention (by design) is that the user will make all such payments 
		   to a given employee using a single, dedicated earn code (of type PSL or MAT or WLI, specifically). Given the possibility, 
		   contrary to intended usage, that payments for the employee exist in payroll history within the relevant time period 
		   under two or more distinct insurable, special payment earn codes, processing code will effectively select only the 
		   single earn code that is used last (in order of post date) up through the employee's recent separation date; in the event 
		   that there are two or more distinct qualifying earn codes used for payments on the same "final" post date (by Service Canada rules, 
		   this should be the employee's last day for which paid (separation date)), processing code will select the single earn code
		   with the greatest combination of values for pay sequence and post sequence (which thus serve as further indicators of 
		   "last" usage); in other words, code will select only the top one conforming payment in bPRTH ordered by post date descending, 
		   pay sequence descending, post sequence descending, and then evaluate all conforming payments made under the same earn code 
		   as used for the top one payment, calculating an average amount for these payments during the evaluation.
		   
		   The necessity of selecting a single earn code for evaluation comes from the requirement to report an average payment amount 
		   for the employee, either "per day" or "per week" (these are the two allowed values for the "periodicity" attribute of any 
		   special payment earn code in bPREC), within the relevant time period, of a specific special payment type. Contrariwise, 
		   if payments under multiple earn codes were to be evaluated (under some scheme), then it could become impossible to report 
		   a single periodicity value for the special payments to the employee (given that the multiple earn codes in question could 
		   bear differing periodicity attribute values, making periodicity for the employee's special payments indeterminate); 
		   similarly, the multiple earn codes in question could bear distinct values for special payment type, again introducing 
		   indeterminacy in face of a requirement to report a single determinate value (for type). Additionally, evaluation of 
		   special payments under multiple earn codes would pose formidable design (and user-comprehensibility) challenges with 
		   respect to the requirement to report a single amount (per day or per week) for the collection of special payments 
		   under consideration. Note that, as it is, processing code will simply calculate an average amount for all conforming 
		   payments under a single special payment earn code (without any attempt to identify such payments as "daily" or "weekly" 
		   based on actual timecard post date values); the periodicity value that will be reported for the special payments 
		   will be the periodicity attribute value of the earn code under which the payments are made. One consequence of this 
		   is that it will be incumbent upon the user to post a single special payment timecard for the employee exactly once per day 
		   or once per week, in conformity with the periodicity attribute value of the earn code used for such payments. An irregular 
		   payment posting schedule would result in an inaccurate calculation for average daily or weekly special payment amount 
		   during processing; the resulting (inaccurate) average payment amount would then need to be corrected by the user 
		   by means of manual edit in the ROE history form. */

	--Select last special payment for each employee in order to identify single earn code
	;WITH cteLastSpecialPaymtByEmp
	AS
	(
			SELECT *
			FROM 
			(
					SELECT	tmpMain.PRCo, tmpMain.Employee, tmpMain.ROEDate, tmpMain.SpecialPaymentStartDate, tmpMain.LastDayPaid,
							Timecard.PRGroup, Timecard.PREndDate, Timecard.PostDate, Timecard.PaySeq, Timecard.PostSeq, Timecard.EarnCode,
							EarnCd.[Description], EarnCd.InsurableEarningsYN, EarnCd.ROESpecialYN, EarnCd.ROEType, EarnCd.ROEPeriod, 
							ROW_NUMBER() OVER
								(
									PARTITION BY tmpMain.PRCo, tmpMain.Employee
									ORDER BY Timecard.PostDate DESC, Timecard.PaySeq DESC, Timecard.PostSeq DESC
								) AS PaymentOrdinal
					FROM	#tmptableROEMain tmpMain
					JOIN	dbo.bPRTH Timecard
								ON Timecard.PRCo = tmpMain.PRCo
								AND Timecard.PRGroup = tmpMain.PRGroup
								AND Timecard.Employee = tmpMain.Employee
								AND Timecard.PREndDate BETWEEN tmpMain.InitialPayPeriodEndDate15a AND tmpMain.FinalPayPeriodEndDate
					JOIN	dbo.bPREC EarnCd
								ON EarnCd.PRCo = Timecard.PRCo
								AND EarnCd.EarnCode = Timecard.EarnCode
					JOIN	dbo.bPRSQ PaySeq
								ON PaySeq.PRCo = Timecard.PRCo
								AND PaySeq.PRGroup = Timecard.PRGroup
								AND PaySeq.PREndDate = Timecard.PREndDate
								AND PaySeq.Employee = Timecard.Employee
								AND PaySeq.PaySeq = Timecard.PaySeq
					WHERE	tmpMain.InsertedHistoryYN = 'Y'				--Process only main temp table rows previously inserted into main history table successfully
						AND	NOT (tmpMain.SpecialPaymentStartDate IS NULL OR tmpMain.SpecialPaymentStartDate = '')	--Start date exists for employee in workfile (now main temp table)
						AND	EarnCd.InsurableEarningsYN = 'Y'			--Earncode flagged for insurable earnings amount
						AND	EarnCd.ROESpecialYN = 'Y'					--Earncode flagged for special payment
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
						AND Timecard.PostDate BETWEEN tmpMain.SpecialPaymentStartDate AND tmpMain.LastDayPaid		--Special payment (timecard) date within special payment time period
			) SpecialPaymtsByEmp										--Conforming special payments by PRCo, Employee
			WHERE SpecialPaymtsByEmp.PaymentOrdinal = 1					--Limit to top one special payment (per PRCo, Employee) ordered by post date desc, pay seq desc, post seq desc
	)

	--Insert one row per employee indicating average special payment amount
	INSERT INTO #tmptableROESSPay
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
			'PRCo'							= tmpMain.PRCo,
			'Employee'						= tmpMain.Employee,
			'ROEDate'						= tmpMain.ROEDate,
			'Category'						= 'SP',			--Constant required because value (per se) does not exist in tables
			'Number'						= 1,			--Constant permissible because grouping below guarantees no more than one row per PRCo, Employee (as required)
			'StatutoryHolidayPaymentDate'	= NULL,
			'OtherMoniesCode'				= NULL,
			'SpecialPaymentStartDate'		= tmpMain.SpecialPaymentStartDate,
			'SpecialPaymentCode'			= EarnCd.ROEType,
			'SpecialPaymentPeriod'			= EarnCd.ROEPeriod,
			'Amount'						= ROUND(AVG(Timecard.Amt),2)
	FROM	#tmptableROEMain tmpMain
	JOIN	dbo.bPRTH Timecard
				ON Timecard.PRCo = tmpMain.PRCo
				AND Timecard.PRGroup = tmpMain.PRGroup
				AND Timecard.Employee = tmpMain.Employee
				AND Timecard.PREndDate BETWEEN tmpMain.InitialPayPeriodEndDate15a AND tmpMain.FinalPayPeriodEndDate
	JOIN	dbo.bPREC EarnCd
				ON EarnCd.PRCo = Timecard.PRCo
				AND EarnCd.EarnCode = Timecard.EarnCode
	JOIN	dbo.bPRSQ PaySeq
				ON PaySeq.PRCo = Timecard.PRCo
				AND PaySeq.PRGroup = Timecard.PRGroup
				AND PaySeq.PREndDate = Timecard.PREndDate
				AND PaySeq.Employee = Timecard.Employee
				AND PaySeq.PaySeq = Timecard.PaySeq
	JOIN	cteLastSpecialPaymtByEmp LastPaymt				--Limit to timecards with same earncode as last special payment (timecard) for employee
				ON LastPaymt.PRCo = Timecard.PRCo
				AND LastPaymt.Employee = Timecard.Employee
				AND LastPaymt.EarnCode = Timecard.EarnCode
	WHERE	tmpMain.InsertedHistoryYN = 'Y'					--Process only main temp table rows previously inserted into main history table successfully
		AND	NOT (tmpMain.SpecialPaymentStartDate IS NULL OR tmpMain.SpecialPaymentStartDate = '')	--Start date exists for employee in workfile (now main temp table)
		AND	EarnCd.InsurableEarningsYN = 'Y'				--Earncode flagged for insurable earnings amount
		AND	EarnCd.ROESpecialYN = 'Y'						--Earncode flagged for special payment
		AND	PaySeq.Processed = 'Y'							--Employee pay sequence already processed
		AND Timecard.PostDate BETWEEN tmpMain.SpecialPaymentStartDate AND tmpMain.LastDayPaid		--Special payment date within special payment time period
	GROUP BY	tmpMain.PRCo,								--Effectively grouped by PRCo, Employee only; permits calculation of average payment amount
				tmpMain.Employee,
				tmpMain.ROEDate,
				tmpMain.SpecialPaymentStartDate,
				EarnCd.ROEType,
				EarnCd.ROEPeriod


END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEInitializeLoadSSPay] TO [public]
GO
