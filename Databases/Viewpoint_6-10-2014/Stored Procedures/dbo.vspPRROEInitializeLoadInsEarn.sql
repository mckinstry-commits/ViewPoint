SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRROEInitializeLoadInsEarn]

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

This procedure assembles the record set that is later inserted into the InsEarn history table (vPRROEEmployeeInsurEarningsPPD).
(Each row in the InsEarn history table contains the insurable earnings amount sum for a single pay period for an ROE for 
an employee.) Specifically, this procedure inserts rows into the insurable earnings temp table (#tmptableROEInsEarn), using 
the pay period control table (bPRPC) and the pay sequence totals table (bPRDT) as primary data sources, and then proceeds 
to update some of those rows with calculated values representing sums of insurable separation payment amounts.

See inline comments within procedure for full details. See also the general overview of ROE initialization processing in the 
opening flowerbox comments within the primary procedure (vspPRROEInitializeMain).

*****************************************************************************************************************************/

AS

BEGIN

	SET NOCOUNT ON

	/* Raise error and exit if insurable earnings temp table (#tmptableROEInsEarn) does not exist */

	IF OBJECT_ID('tempdb..#tmptableROEInsEarn') IS NULL
		BEGIN

			DECLARE @ErrorMessage varchar(255)
			SET		@ErrorMessage = 'Temp table #tmptableROEInsEarn, required by procedure vspPRROEInitializeLoadInsEarn, does not exist. ' + CHAR(13) + CHAR(10)
									+ 'This procedure is intended to be called from vspPRROEInitializeMain, where that temp table is defined.'

			RAISERROR(@ErrorMessage,16,1)

			RETURN 1

		END


	/* Insert rows (primarily from pay period control table bPRPC) into insurable earnings temp table */
		/* For each employee whose ROE was inserted successfully into main history table above, a row exists now in main temp table 
		   with an indicator of success (InsertedHistoryYN = 'Y'). All and only these rows in main temp table should be processed further. 
		   For each such row: Load one row for each pay period for the employee's payroll group constrained within the employee's 
		   "limited" period of employment (defined as the set of pay periods between initial pay period end date for Block 15c and 
		   final pay period end date, inclusive of end points). For each pay period, sum up pay sequence total amounts in bPRDT 
		   associated with a) earn codes that are designated in bPREC as "insurable earnings", and b) liability codes that are 
		   designated in bPRDL as "ROE insurable"; include amounts only if related employee pay sequence in bPRSQ has been processed; 
		   for this initial insert, exclude amounts associated with any earn code that is designated in bPREC as intended for 
		   "separation payment" usage only. (In subsequent update below, all insurable separation payment amounts made within the 
		   employee's "limited" period of employment (for Block 15c) will be allocated artificially to the final pay period, regardless 
		   of the pay period in which the payments were actually made.) If, for any given pay period, the employee has no insurable earnings 
		   (other than separation payments), then insert a zero value (not NULL) for earnings amount indicating a "nil pay period". */

	INSERT INTO #tmptableROEInsEarn
	(
		[PRCo],
		[Employee],
		[ROEDate],
		[PayPeriodEndingDate],
		[InsurableEarnings]
	)
	SELECT
		'PRCo'					= tmpMain1.PRCo,
		'Employee'				= tmpMain1.Employee,
		'ROEDate'				= tmpMain1.ROEDate,
		'PayPeriodEndingDate'	= PayPrd.PREndDate,
		'InsurableEarnings'		= ISNULL(InsEarnsByPayPrd.Amount,0)		--Insert 0 for any nil pay period for employee
	FROM	#tmptableROEMain tmpMain1
	JOIN	dbo.bPRPC PayPrd
				ON PayPrd.PRCo = tmpMain1.PRCo
				AND PayPrd.PRGroup = tmpMain1.PRGroup
				AND PayPrd.PREndDate BETWEEN tmpMain1.InitialPayPeriodEndDate15c AND tmpMain1.FinalPayPeriodEndDate
	LEFT JOIN		--Left join allows for non-existence of insurable earnings for a given ("nil") pay period
	(
			SELECT	InsEarnsDetail.PRCo, InsEarnsDetail.Employee, InsEarnsDetail.PREndDate, SUM(InsEarnsDetail.Amount) AS Amount
			FROM
			(
					--Earnings pay sequence details
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, PaySeqDetail.PREndDate, PaySeqDetail.Amount
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRDT PaySeqDetail
								ON PaySeqDetail.PRCo = tmpMain2.PRCo
								AND PaySeqDetail.PRGroup = tmpMain2.PRGroup
								AND PaySeqDetail.Employee = tmpMain2.Employee
								AND PaySeqDetail.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15c AND tmpMain2.FinalPayPeriodEndDate
					JOIN	dbo.bPREC EarnCd
								ON EarnCd.PRCo = PaySeqDetail.PRCo
								AND EarnCd.EarnCode = PaySeqDetail.EDLCode
					JOIN	dbo.bPRSQ PaySeq
								ON PaySeq.PRCo = PaySeqDetail.PRCo
								AND PaySeq.PRGroup = PaySeqDetail.PRGroup
								AND PaySeq.PREndDate = PaySeqDetail.PREndDate
								AND PaySeq.Employee = PaySeqDetail.Employee
								AND PaySeq.PaySeq = PaySeqDetail.PaySeq
					WHERE	PaySeqDetail.EDLType = 'E'					--Earnings
						AND	EarnCd.InsurableEarningsYN = 'Y'			--Earncode flagged for insurable earnings amount
						AND	EarnCd.ROESeparationYN = 'N'				--Earncode not flagged for separation payment
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed

					UNION ALL

					--Liability pay sequence details
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, PaySeqDetail.PREndDate, PaySeqDetail.Amount
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRDT PaySeqDetail
								ON PaySeqDetail.PRCo = tmpMain2.PRCo
								AND PaySeqDetail.PRGroup = tmpMain2.PRGroup
								AND PaySeqDetail.Employee = tmpMain2.Employee
								AND PaySeqDetail.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15c AND tmpMain2.FinalPayPeriodEndDate
					JOIN	dbo.bPRDL DednLiab
								ON DednLiab.PRCo = PaySeqDetail.PRCo
								AND DednLiab.DLCode = PaySeqDetail.EDLCode
					JOIN	dbo.bPRSQ PaySeq
								ON PaySeq.PRCo = PaySeqDetail.PRCo
								AND PaySeq.PRGroup = PaySeqDetail.PRGroup
								AND PaySeq.PREndDate = PaySeqDetail.PREndDate
								AND PaySeq.Employee = PaySeqDetail.Employee
								AND PaySeq.PaySeq = PaySeqDetail.PaySeq
					WHERE	PaySeqDetail.EDLType = 'L'					--Liability
						AND	DednLiab.ROEInsurableYN = 'Y'				--Liabcode flagged for ROE insurable amount
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
			)	InsEarnsDetail											--Insurable earnings (and liability) amount details
			GROUP BY InsEarnsDetail.PRCo, InsEarnsDetail.Employee, InsEarnsDetail.PREndDate
	) InsEarnsByPayPrd													--Insurable earnings (and liabilities) sum by PRCo, Employee, Pay period
			ON InsEarnsByPayPrd.PRCo = tmpMain1.PRCo AND InsEarnsByPayPrd.Employee = tmpMain1.Employee AND InsEarnsByPayPrd.PREndDate = PayPrd.PREndDate
	WHERE	tmpMain1.InsertedHistoryYN = 'Y'							--Process only main temp table rows previously inserted into main history table successfully


	/* Update rows in insurable earnings temp table, adding sum of insurable separation payment amounts to employee's final pay period row only */

	UPDATE	tempInsEarn
	SET		tempInsEarn.InsurableEarnings = tempInsEarn.InsurableEarnings + InsSepPaymtsByEmp.Amount	--Both addends disallow nulls in source tables
	FROM	#tmptableROEInsEarn tempInsEarn
	JOIN	#tmptableROEMain tmpMain
				ON tmpMain.PRCo = tempInsEarn.PRCo
				AND tmpMain.Employee = tempInsEarn.Employee
				AND tmpMain.FinalPayPeriodEndDate = tempInsEarn.PayPeriodEndingDate		--Restrict to final pay period for employee
	JOIN	--Join returns no row, thus as desired does not update insurable earnings temp table, if no conforming separation payments exist for employee
	(
			SELECT	tmpMain.PRCo, tmpMain.Employee, SUM(PaySeqDetail.Amount) AS Amount
			FROM	#tmptableROEMain tmpMain
			JOIN	dbo.bPRDT PaySeqDetail
						ON PaySeqDetail.PRCo = tmpMain.PRCo
						AND PaySeqDetail.PRGroup = tmpMain.PRGroup
						AND PaySeqDetail.Employee = tmpMain.Employee
						AND PaySeqDetail.PREndDate BETWEEN tmpMain.InitialPayPeriodEndDate15c AND tmpMain.FinalPayPeriodEndDate
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
				AND	EarnCd.InsurableEarningsYN = 'Y'			--Earncode flagged for insurable earnings amount
				AND	EarnCd.ROESeparationYN = 'Y'				--Earncode flagged for separation payment
				AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
			GROUP BY tmpMain.PRCo, tmpMain.Employee
	)	InsSepPaymtsByEmp										--Separation payments sum by PRCo, Employee
			ON InsSepPaymtsByEmp.PRCo = tempInsEarn.PRCo AND InsSepPaymtsByEmp.Employee = tempInsEarn.Employee


END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEInitializeLoadInsEarn] TO [public]
GO
