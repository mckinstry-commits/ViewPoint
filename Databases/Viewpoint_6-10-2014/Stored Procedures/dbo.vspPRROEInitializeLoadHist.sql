SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRROEInitializeLoadHist]

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

This procedure assembles the record set that is later inserted into the Hist (main) history table (vPRROEEmployeeHistory). 
(Each row in the Hist (main) history table represents an ROE for an employee.) Specifically, this procedure inserts rows into 
the main temp table (#tmptableROEMain), using the workfile table (vPRROEEmployeeWorkfile) as primary data source, and then 
proceeds to update those rows (iteratively) with several calculated values for each employee's ROE.

See inline comments within procedure for full details. See also the general overview of ROE initialization processing in the 
opening flowerbox comments within the primary procedure (vspPRROEInitializeMain).

*****************************************************************************************************************************/

(
	@PRCo	bCompany
)

AS

BEGIN

	SET NOCOUNT ON

	/* Raise error and exit if main temp table (#tmptableROEMain) does not exist */

	IF OBJECT_ID('tempdb..#tmptableROEMain') IS NULL
		BEGIN

			DECLARE @ErrorMessage varchar(255)
			SET		@ErrorMessage = 'Temp table #tmptableROEMain, required by procedure vspPRROEInitializeLoadHist, does not exist. ' + CHAR(13) + CHAR(10)
									+ 'This procedure is intended to be called from vspPRROEInitializeMain, where that temp table is defined.'

			RAISERROR(@ErrorMessage,16,1)

			RETURN 1

		END


	/* Insert rows (primarily from workfile table vPRROEEmployeeWorkfile) into main temp table */
		/* Load only processable workfile rows that passed all validation tests. Calculate and insert Final Pay Period End Date.
		   Insert preliminary (zero or null) placeholder values for: Total Insurable Hours; Total Insurable Earnings; Initial Pay
		   Period End Date for Block 15a; Initial Pay Period End Date for Block 15b; Initial Pay Period End Date for Block 15c.
		   In subsequent update queries, calculate actual values for these columns and update main temp table. */

	INSERT INTO #tmptableROEMain
	(
		[WorkfileKeyID],
		[PRCo],
		[Employee],
		[ROEDate],
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
		[SpecialPaymentStartDate],
		[TotalInsurableHours],
		[TotalInsurableEarnings],
		[ReasonForROE],
		[ContactFirstName],
		[ContactLastName],
		[ContactAreaCode],
		[ContactPhoneNbr],
		[ContactPhoneExt],
		[Comments],
		[PayPeriodType],
		[Language],
		[PRGroup],
		[InitialPayPeriodEndDate15a],
		[InitialPayPeriodEndDate15b],
		[InitialPayPeriodEndDate15c],
		[InsertedHistoryYN]
	)
	SELECT
		'WorkfileKeyID'					= Work.KeyID,
		'PRCo'							= Work.PRCo,
		'Employee'						= Work.Employee,
		'ROEDate'						= Work.ROEDate,
		'SIN'							= REPLACE(Emp.SSN,'-',''),
		'FirstName'						= LEFT(Emp.FirstName,20),
		'MiddleInitial'					= LEFT(Emp.MidName,4),
		'LastName'						= LEFT(Emp.LastName,28),
		'AddressLine1'					= LEFT(Emp.[Address],35),
		'AddressLine2'					= LEFT(Emp.City,35),
		'AddressLine3'					= LEFT
											(
												ISNULL(Emp.[State],'') + (CASE WHEN Emp.[State] IS NULL THEN '' ELSE ', ' END) + 
												ISNULL(Emp.Country,'') + (CASE WHEN Emp.Country IS NULL THEN '' ELSE ', ' END) + 
												ISNULL(Emp.Zip,''),
												35
											),
		'EmployeeOccupation'			= Occup.[Description],
		'FirstDayWorked'				= Emp.RecentRehireDate,
		'LastDayPaid'					= Emp.RecentSeparationDate,
		'FinalPayPeriodEndDate'			= FinalPayPrd.PREndDate,
		'ExpectedRecallCode'			= Work.ExpectedRecallCode,
		'ExpectedRecallDate'			= Work.ExpectedRecallDate,
		'SpecialPaymentStartDate'		= Work.SpecialPaymentsStartDate,
		'TotalInsurableHours'			= 0,							--Placeholder value; actual value calculated and updated below
		'TotalInsurableEarnings'		= 0,							--Placeholder value; actual value calculated and updated below
		'ReasonForROE'					= Work.ReasonForROE,
		'ContactFirstName'				= Work.ContactFirstName,
		'ContactLastName'				= Work.ContactLastName,
		'ContactAreaCode'				= Work.ContactAreaCode,
		'ContactPhoneNbr'				= Work.ContactPhoneNbr,
		'ContactPhoneExt'				= Work.ContactPhoneExt,
		'Comments'						= Work.Comments,
		'PayPeriodType'					= Grp.PayFreq,
		'Language'						= Work.[Language],
		'PRGroup'						= Emp.PRGroup,
		'InitialPayPeriodEndDate15a'	= NULL,							--Placeholder value; actual value calculated and updated below
		'InitialPayPeriodEndDate15b'	= NULL,							--Placeholder value; actual value calculated and updated below
		'InitialPayPeriodEndDate15c'	= NULL,							--Placeholder value; actual value calculated and updated below
		'InsertedHistoryYN'				= 'N'							--Initial value; updated to 'Y' upon successful insert into main history table
	FROM	dbo.vPRROEEmployeeWorkfile Work
	JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
	JOIN	dbo.bPRGR Grp ON Grp.PRCo = Emp.PRCo AND Grp.PRGroup = Emp.PRGroup
	JOIN
	(
			SELECT	Emp.PRCo, Emp.Employee, MIN(PayPrd.PREndDate) AS PREndDate					--Single PREndDate that follows employee's Separation Date most closely is "final" one
			FROM	dbo.vPRROEEmployeeWorkfile Work
			JOIN	dbo.bPREH Emp ON Emp.PRCo = Work.PRCo AND Emp.Employee = Work.Employee
			JOIN	dbo.bPRPC PayPrd ON PayPrd.PRCo = Emp.PRCo AND PayPrd.PRGroup = Emp.PRGroup					--Join requires existence in PR Pay Period Control, previously validated
								AND (Emp.RecentSeparationDate BETWEEN PayPrd.BeginDate AND PayPrd.PREndDate)	--Pay period includes employee's Most Recent Separation Date
			WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()				--Processable in workfile table
				AND Work.ValidationTier IS NULL																	--Not invalidated by any validation test
			GROUP BY Emp.PRCo, Emp.Employee
	)	FinalPayPrd
			ON FinalPayPrd.PRCo = Emp.PRCo AND FinalPayPrd.Employee = Emp.Employee
	LEFT JOIN dbo.bPROP Occup ON Occup.PRCo = Emp.PRCo AND Occup.OccupCat = Emp.OccupCat
	WHERE	Work.PRCo = @PRCo AND Work.ProcessYN = 'Y' AND Work.VPUserName = SUSER_SNAME()		--Processable in workfile table
		AND	Work.ValidationTier IS NULL															--Not invalidated by any validation test


	/* Update each row in main temp table with three initial (earliest) pay period end date values (15a; 15b; 15c) */
		/* Initial pay period end date values for Blocks 15a, 15b, and 15c, respectively, may differ from one another due to
		   differing rules concerning maximum pay period counts. For a given ROE, the initial pay period end date for, say,
		   Block 15a, represents the earliest PREndDate in a limited set of pay periods within the employee's period of
		   employment, and is determined to be the more recent of two values: 1) for the employee's PRGroup, the earliest
		   PREndDate equal to or later than the employee's recent rehire date; or 2) for the employee's PRGroup, the earliest
		   PREndDate within the set of pay periods culminating with the employee's Final Pay Period End Date and including
		   some number of prior, consecutive pay periods, for a total pay period count, X, representing a maximum pay period 
		   count that varies by the pay frequency of the employee's PRGroup and is dictated by Service Canada rules. */


	--Determine and update initial pay period end date for Block 15a
	UPDATE	tmpMain1
	SET		tmpMain1.InitialPayPeriodEndDate15a = InitialPayPrd15a.PREndDate
	FROM	#tmptableROEMain tmpMain1
	JOIN
	(
			SELECT	tmpMain2.PRCo, tmpMain2.Employee, MIN(PeriodOfEmployment.PREndDate) AS PREndDate		--Earliest PREndDate in "limited" period of employment is "initial" one
			FROM	#tmptableROEMain tmpMain2
			CROSS APPLY
			(
					SELECT	TOP
					(
						CASE tmpMain2.PayPeriodType
							WHEN 'W' THEN 53 WHEN 'B' THEN 27 WHEN 'S' THEN 25 WHEN 'M' THEN 13 ELSE 0 END	--Maximum pay period count varies by pay frequency of employee's PRGroup
					)	PayPrd.PREndDate AS PREndDate
					FROM	dbo.bPRPC PayPrd
					WHERE	PayPrd.PRCo = tmpMain2.PRCo														--Criteria for APPLY operator
						AND PayPrd.PRGroup = tmpMain2.PRGroup
						AND PayPrd.PREndDate BETWEEN tmpMain2.FirstDayWorked AND tmpMain2.FinalPayPeriodEndDate
					ORDER BY PayPrd.PREndDate DESC
			)	PeriodOfEmployment																			--Employee's period of employment, limited by maximum pay period count
			GROUP BY tmpMain2.PRCo, tmpMain2.Employee
	)	InitialPayPrd15a																					--Initial pay period for Block 15a
			ON InitialPayPrd15a.PRCo = tmpMain1.PRCo AND InitialPayPrd15a.Employee = tmpMain1.Employee


	--Determine and update initial pay period end date for Block 15b
	UPDATE	tmpMain1
	SET		tmpMain1.InitialPayPeriodEndDate15b = InitialPayPrd15b.PREndDate
	FROM	#tmptableROEMain tmpMain1
	JOIN
	(
			SELECT	tmpMain2.PRCo, tmpMain2.Employee, MIN(PeriodOfEmployment.PREndDate) AS PREndDate		--Earliest PREndDate in "limited" period of employment is "initial" one
			FROM	#tmptableROEMain tmpMain2
			CROSS APPLY
			(
					SELECT	TOP
					(
						CASE tmpMain2.PayPeriodType
							WHEN 'W' THEN 27 WHEN 'B' THEN 14 WHEN 'S' THEN 13 WHEN 'M' THEN 7 ELSE 0 END	--Maximum pay period count varies by pay frequency of employee's PRGroup
					)	PayPrd.PREndDate AS PREndDate
					FROM	dbo.bPRPC PayPrd
					WHERE	PayPrd.PRCo = tmpMain2.PRCo														--Criteria for APPLY operator
						AND PayPrd.PRGroup = tmpMain2.PRGroup
						AND PayPrd.PREndDate BETWEEN tmpMain2.FirstDayWorked AND tmpMain2.FinalPayPeriodEndDate
					ORDER BY PayPrd.PREndDate DESC
			)	PeriodOfEmployment																			--Employee's period of employment, limited by maximum pay period count
			GROUP BY tmpMain2.PRCo, tmpMain2.Employee
	)	InitialPayPrd15b																					--Initial pay period for Block 15b
			ON InitialPayPrd15b.PRCo = tmpMain1.PRCo AND InitialPayPrd15b.Employee = tmpMain1.Employee


	--Determine and update initial pay period end date for Block 15c
	--For Block 15c, current rules concerning maximum pay period count are the same as for Block 15a; thus, set 15c value same as 15a
	UPDATE	tmpMain1
	SET		tmpMain1.InitialPayPeriodEndDate15c = tmpMain1.InitialPayPeriodEndDate15a
	FROM	#tmptableROEMain tmpMain1


	/* Update each row in main temp table with calculated value for total insurable hours (Block 15a) */
		/* For each employee's "limited" period of employment (defined as the set of pay periods between initial pay period
		   end date for Block 15a and final pay period end date, inclusive of end points), sum up timecard hours in bPRTH associated 
		   with earn codes that are designated in bPREC as "insurable hours"; include timecard only if related employee pay sequence 
		   in bPRSQ has been processed. If employee's separation is final (Recall Code = 'N' or Reason for ROE in ('E','G','M')), 
		   exclude any timecard (bPRTH record) whose earn code is designated in bPREC as statutory holiday and whose post date 
		   falls after employee's last day for which paid (recent separation date). Round total hours to the nearest integer. 
		   If total insurable hours for employee is null, leave zero placeholder value in place. */

	UPDATE	tmpMain1
	SET		tmpMain1.TotalInsurableHours = ROUND(TotalInsHoursByEmp.[Hours],0)
	FROM	#tmptableROEMain tmpMain1
	JOIN										--Join returns no row, thus as desired does not update main temp table, if no conforming timecards exist for employee
	(
			SELECT	tmpMain2.PRCo, tmpMain2.Employee, SUM(Timecard.[Hours]) AS [Hours]
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
			WHERE	EarnCd.InsurableHoursYN = 'Y'				--Earncode flagged for insurable hours
				AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed
				AND	Timecard.PostDate <=						--Include timecard hours only when post date is on or before recent separation date...
				(
					CASE										--...if timecard earncode is Separation-StatHoliday and separation is final
						WHEN EarnCd.ROECategory = 'SH' AND (tmpMain2.ExpectedRecallCode = 'N' OR tmpMain2.ReasonForROE IN ('E','G','M'))
						THEN tmpMain2.LastDayPaid
						ELSE Timecard.PostDate END
				)
			GROUP BY tmpMain2.PRCo, tmpMain2.Employee
	)	TotalInsHoursByEmp										--Total insurable hours by PRCo and Employee
			ON TotalInsHoursByEmp.PRCo = tmpMain1.PRCo AND TotalInsHoursByEmp.Employee = tmpMain1.Employee


	/* Update each row in main temp table with calculated value for total insurable earnings (Block 15b) */
		/* For each employee's "limited" period of employment (defined as the set of pay periods between initial pay period
		   end date for Block 15b and final pay period end date, inclusive of end points), sum up pay sequence total amounts 
		   in bPRDT associated with a) earn codes that are designated in bPREC as "insurable earnings", and b) liability codes 
		   that are designated in bPRDL as "ROE insurable"; include amounts only if related employee pay sequence in bPRSQ 
		   has been processed. If total insurable earnings for employee is null, leave zero placeholder value in place. */

	UPDATE	tmpMain1
	SET		tmpMain1.TotalInsurableEarnings = TotalInsEarnsByEmp.Amount
	FROM	#tmptableROEMain tmpMain1
	JOIN										--Join returns no row, thus as desired does not update main temp table, if no conforming pay sequence details exist for employee
	(
			SELECT	InsEarnsDetail.PRCo, InsEarnsDetail.Employee, SUM(InsEarnsDetail.Amount) AS Amount
			FROM
			(
					--Earnings pay sequence details
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, PaySeqDetail.Amount
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRDT PaySeqDetail
								ON PaySeqDetail.PRCo = tmpMain2.PRCo
								AND PaySeqDetail.PRGroup = tmpMain2.PRGroup
								AND PaySeqDetail.Employee = tmpMain2.Employee
								AND PaySeqDetail.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15b AND tmpMain2.FinalPayPeriodEndDate
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
						AND	PaySeq.Processed = 'Y'						--Employee pay sequence already processed

					UNION ALL

					--Liability pay sequence details
					SELECT	tmpMain2.PRCo, tmpMain2.Employee, PaySeqDetail.Amount
					FROM	#tmptableROEMain tmpMain2
					JOIN	dbo.bPRDT PaySeqDetail
								ON PaySeqDetail.PRCo = tmpMain2.PRCo
								AND PaySeqDetail.PRGroup = tmpMain2.PRGroup
								AND PaySeqDetail.Employee = tmpMain2.Employee
								AND PaySeqDetail.PREndDate BETWEEN tmpMain2.InitialPayPeriodEndDate15b AND tmpMain2.FinalPayPeriodEndDate
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
			GROUP BY InsEarnsDetail.PRCo, InsEarnsDetail.Employee
	)	TotalInsEarnsByEmp												--Total insurable earnings (and liabilities) by PRCo and Employee
			ON TotalInsEarnsByEmp.PRCo = tmpMain1.PRCo AND TotalInsEarnsByEmp.Employee = tmpMain1.Employee


END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEInitializeLoadHist] TO [public]
GO
