SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[brptPRRegisterTotals]
(
	@PRCo			tinyint,
	@BegPRGroup		tinyint			= 0,
	@EndPRGroup		tinyint			= 255,
	@BegPREndDate	smalldatetime,
	@EndPREndDate	smalldatetime
)

AS
       
/**************************************************************************************

Author:			JH
Date Created:	10/18/2005
Reports:		PR Payroll Register Totals (PRRegisterTotals.rpt)

Purpose:		Returns total earnings, deductions, and liabilities for the specified
				PRCo, range of PRGroup values, and range of PREndDate values.

Revision History      
Date		Author	Issue	Description
10/18/2005	JH		-		Copied from brptPRRegister, modified to exclude PRGroup in
							WHERE clauses.
12/21/2006	CR		123006	Added PRGroup.
06/13/2007	JH		123920	Removed link between PRDT and PREH for earnings,
							deductions, and liabilities.
10/05/2012	CUC		B-10952	Revised to handle deduction payback amounts; added
							parameter default values; updated obsolete data type
							definitions; removed extraneous and obsolete code;
							corrected several defects, including ordering by EDLCode
							for earnings and liabilities, and proper separation of
							posted earn codes and add-on earn codes; reformatted for
							legibility.

**************************************************************************************/

SET NOCOUNT ON

DECLARE @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee, @PaySeq tinyint, @EDLCode bEDLCode
DECLARE @Amount bDollar, @Rate bUnitCost, @Hours bHrs
DECLARE @RecId int, @Desc bDesc


/* Create temp table to hold values for final selection */
 
CREATE TABLE dbo.#a
(
	[RecId]				int	IDENTITY(1,1)	NOT NULL,
	[PRCo]				tinyint				NOT NULL,	--bCompany
	[PRGroup]			tinyint				NULL,		--bGroup
	[PREndDate]			smalldatetime		NULL,		--bDate
	[PREmployee]		int					NULL,		--bEmployee
	[PaySeq]			tinyint				NULL,
	[AddOnYN]			char(1)				NULL,
	[EarnCode]			smallint			NULL,		--bEDLCode
	[EarnAmt]			numeric(12,2)		NULL,		--bDollar
	[EarnHours]			numeric(10,2)		NULL,		--bHrs
	[EarnRate]			numeric(16,5)		NULL,		--bUnitCost
	[EarnDescription]	varchar(30)			NULL,		--bDesc
	[DedCode]			smallint			NULL,		--bEDLCode
	[DedAmt]			numeric(12,2)		NULL,		--bDollar
	[DedDescription]	varchar(60)			NULL,		--bDesc
	[DedType]			varchar(16)			NULL,
	[LiabCode]			smallint			NULL,		--bEDLCode
	[LiabAmt]			numeric(12,2)		NULL,		--bDollar
	[LiabDescription]	varchar(30)			NULL,		--bDesc
	[TotEarnAmt]		numeric(12,2)		NULL,		--bDollar
	[TotEarnHours]		numeric(10,2)		NULL,		--bHrs
	[TotDedAmt]			numeric(12,2)		NULL,		--bDollar
	[TotLiabAmt]		numeric(12,2)		NULL		--bDollar
)

CREATE CLUSTERED INDEX [aindex] ON dbo.#a
	([PRCo], [PRGroup], [PREndDate], [PREmployee], [PaySeq], [RecId])

CREATE NONCLUSTERED INDEX [bindex] ON dbo.#a
	([RecId])


/* DEDUCTIONS */
/* Insert initial rows (deductions, from PRDT) into temp table */

/* Insert detail rows for employees and pay sequences */

INSERT INTO dbo.#a
(
	[PRCo],
	[PRGroup],
	[PREndDate],
	[PREmployee],
	[PaySeq],
	[DedCode],
	[DedAmt],
	[DedDescription],
	[DedType]
)
SELECT					--Regular deductions (non-payback)
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'PREmployee'		= PRDT.Employee,
	'PaySeq'			= PRDT.PaySeq,
	'DedCode'			= PRDT.EDLCode,
	'DedAmount'			= CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END,
	'DedDescription'	= PRDL.[Description],
	'DedType'			= '1-RegularDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
AND PRDT.PREndDate BETWEEN @BegPREndDate AND @EndPREndDate
AND PRDT.EDLType = 'D'
UNION
SELECT					--Payback deductions
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'PREmployee'		= PRDT.Employee,
	'PaySeq'			= PRDT.PaySeq,
	'DedCode'			= PRDT.EDLCode,
	'DedAmount'			= CASE WHEN PRDT.PaybackOverYN = 'Y' THEN PRDT.PaybackOverAmt ELSE PRDT.PaybackAmt END,
	'DedDescription'	= 'Payback - ' + ISNULL(PRDL.[Description],''),
	'DedType'			= '2-PaybackDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
AND PRDT.PREndDate BETWEEN @BegPREndDate AND @EndPREndDate
AND PRDT.EDLType = 'D'
--Include payback row if there is a non-zero payback amount or if payback override flag is set
AND (PRDT.PaybackAmt <> 0 OR PRDT.PaybackOverYN = 'Y')
ORDER BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.Employee, PRDT.PaySeq, PRDT.EDLCode, DedType

/* Insert summary rows for Totals section */
/* Note that summary rows in table #a may later be identified as rows where PREmployee is null */

INSERT INTO dbo.#a
(
	[PRCo],
	[DedCode],
	[TotDedAmt],
	[DedDescription],
	[DedType]
)
SELECT					--Regular deductions (non-payback)
	'PRCo'				= PRDT.PRCo,
	'DedCode'			= PRDT.EDLCode,
	'TotDedAmt'			= SUM(CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END),
	'DedDescription'	= PRDL.[Description],
	'DedType'			= '1-RegularDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
AND PRDT.PREndDate BETWEEN @BegPREndDate AND @EndPREndDate
AND PRDT.EDLType = 'D'
GROUP BY PRDT.PRCo, PRDT.EDLCode, PRDL.[Description]
UNION
SELECT					--Payback deductions
	'PRCo'				= PRDT.PRCo,
	'DedCode'			= PRDT.EDLCode,
	'TotDedAmt'			= SUM(CASE WHEN PRDT.PaybackOverYN = 'Y' THEN PRDT.PaybackOverAmt ELSE PRDT.PaybackAmt END),
	'DedDescription'	= 'Payback - ' + ISNULL(PRDL.[Description],''),
	'DedType'			= '2-PaybackDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
AND PRDT.PREndDate BETWEEN @BegPREndDate AND @EndPREndDate
AND PRDT.EDLType = 'D'
--Include payback row if there is a non-zero payback amount or if payback override flag is set
AND (PRDT.PaybackAmt <> 0 OR PRDT.PaybackOverYN = 'Y')
GROUP BY PRDT.PRCo, PRDT.EDLCode, PRDL.[Description]
ORDER BY PRDT.PRCo, PRDT.EDLCode, DedType


/* EARNINGS, Standard */
/* Update existing rows in temp table with standard earnings (from PRTH); or insert new rows if necessary */

DECLARE bcEarn CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRGroup, PREndDate, Employee, PaySeq, EarnCode, Amt, [Hours], Rate
	FROM dbo.PRTH WITH(NOLOCK)
	WHERE PRCo = @PRCo
	AND PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
	AND PREndDate BETWEEN @BegPREndDate AND @EndPREndDate 
	ORDER BY PRCo, EarnCode, Rate, PRGroup, PREndDate, Employee, PaySeq

OPEN bcEarn
FETCH NEXT FROM bcEarn INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Hours, @Rate

WHILE @@fetch_status = 0
	BEGIN

		SELECT @Desc = [Description] FROM dbo.PREC WITH(NOLOCK) WHERE PRCo = @PRCo AND EarnCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PRGroup = @PRGroup
		AND PREndDate = @PREndDate
		AND PREmployee = @Employee
		AND PaySeq = @PaySeq
		AND (EarnCode IS NULL OR (EarnCode = @EDLCode AND EarnRate = @Rate AND AddOnYN = 'N'))

		IF @RecId IS NOT NULL
			BEGIN
      			UPDATE dbo.#a
      			SET EarnCode = @EDLCode, EarnAmt = ISNULL(EarnAmt,0)+@Amount, EarnHours = ISNULL(EarnHours,0)+@Hours, EarnRate = @Rate, EarnDescription = @Desc, AddOnYN = 'N'
      			WHERE RecId = @RecId
      		END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, PREmployee, PaySeq, EarnCode, EarnAmt, EarnHours, EarnRate, EarnDescription, AddOnYN)
				SELECT @PRCo, @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Hours, @Rate, @Desc, 'N'
			END

		/* Update or insert summary rows for Totals section (no distinct rows by Rate for a given EarnCode) */
		
		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee IS NULL  --Identifies summary rows in table #a
		AND (EarnCode IS NULL OR (EarnCode = @EDLCode AND AddOnYN = 'N'))
		
		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET EarnCode = @EDLCode, TotEarnAmt = ISNULL(TotEarnAmt,0)+@Amount, TotEarnHours = ISNULL(TotEarnHours,0)+@Hours, EarnDescription = @Desc, AddOnYN = 'N'
				WHERE RecId = @RecId
      		END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, EarnCode, TotEarnAmt, TotEarnHours, EarnDescription, AddOnYN)
				SELECT @PRCo, @EDLCode, @Amount, @Hours, @Desc, 'N'
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcEarn INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Hours, @Rate

	END

CLOSE bcEarn
DEALLOCATE bcEarn


/* EARNINGS, Add-on */
/* Update existing rows in temp table with add-on earnings (from PRTA); or insert new rows if necessary */

DECLARE bcPRTA CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRGroup, PREndDate, Employee, PaySeq, EarnCode, Amt, Rate
	FROM dbo.PRTA WITH(NOLOCK)
	WHERE PRCo = @PRCo
	AND PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
	AND PREndDate BETWEEN @BegPREndDate AND @EndPREndDate 
	ORDER BY PRCo, EarnCode, Rate, PRGroup, PREndDate, Employee, PaySeq
      
OPEN bcPRTA
FETCH NEXT FROM bcPRTA INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Rate

WHILE @@fetch_status = 0
	BEGIN
	
		SELECT @Desc = [Description] FROM dbo.PREC WITH(NOLOCK) WHERE PRCo = @PRCo AND EarnCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PRGroup = @PRGroup
		AND PREndDate = @PREndDate
		AND PREmployee = @Employee
		AND PaySeq = @PaySeq
		AND (EarnCode IS NULL OR (EarnCode = @EDLCode AND EarnRate = @Rate AND AddOnYN = 'Y'))

		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET EarnCode = @EDLCode, EarnAmt = ISNULL(EarnAmt,0)+@Amount, EarnRate = @Rate, EarnDescription = @Desc, AddOnYN = 'Y'
      			WHERE RecId = @RecId
      		END
		ELSE
			BEGIN
				 INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, PREmployee, PaySeq, EarnCode, EarnAmt, EarnRate, EarnDescription, AddOnYN)
				 SELECT @PRCo, @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Rate, @Desc, 'Y'
			END

		/* Update or insert summary rows for Totals section (no distinct rows by Rate for a given EarnCode) */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee IS NULL  --Identifies summary rows in table #a
		AND (EarnCode IS NULL OR (EarnCode = @EDLCode AND AddOnYN = 'Y'))
		
		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET EarnCode = @EDLCode, TotEarnAmt = ISNULL(TotEarnAmt,0)+@Amount, EarnDescription = @Desc, AddOnYN = 'Y'
				WHERE RecId = @RecId
			END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, EarnCode, TotEarnAmt, EarnDescription, AddOnYN)
				SELECT @PRCo, @EDLCode, @Amount, @Desc, 'Y'
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcPRTA INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Rate
		
	END

CLOSE bcPRTA
DEALLOCATE bcPRTA


/* LIABILITIES */
/* Update existing rows in temp table with liabilities (from PRDT); or insert new rows if necessary */

DECLARE bcLiab CURSOR LOCAL FAST_FORWARD FOR 
	SELECT PRGroup, PREndDate, Employee, PaySeq, EDLCode, LiabilityAmount = (CASE WHEN UseOver='Y' THEN OverAmt ELSE Amount END)
	FROM dbo.PRDT WITH(NOLOCK)
	WHERE PRCo = @PRCo
	AND PRGroup BETWEEN @BegPRGroup AND @EndPRGroup
	AND PREndDate BETWEEN @BegPREndDate AND @EndPREndDate 
	AND EDLType = 'L'
	ORDER BY PRCo, EDLCode, PRGroup, PREndDate, Employee, PaySeq

OPEN bcLiab
FETCH NEXT FROM bcLiab INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount

WHILE @@fetch_status = 0
	BEGIN

		SELECT @Desc = [Description] FROM dbo.PRDL WITH(NOLOCK) WHERE PRCo = @PRCo AND DLCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PRGroup = @PRGroup
		AND PREndDate = @PREndDate
		AND PREmployee = @Employee
		AND PaySeq = @PaySeq
		AND (LiabCode IS NULL OR LiabCode = @EDLCode)
      	
		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET LiabCode = @EDLCode, LiabAmt = ISNULL(LiabAmt,0)+@Amount, LiabDescription = @Desc
				WHERE RecId = @RecId
      		END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, PREmployee, PaySeq, LiabCode, LiabAmt, LiabDescription)
				SELECT @PRCo, @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount, @Desc
			END

		/* Update or insert summary rows for Totals section */
		
		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee IS NULL  --Identifies summary rows in table #a
		AND (LiabCode IS NULL OR LiabCode = @EDLCode)

		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET LiabCode = @EDLCode, TotLiabAmt = ISNULL(TotLiabAmt,0)+@Amount, LiabDescription = @Desc
				WHERE RecId = @RecId
			END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, LiabCode, TotLiabAmt, LiabDescription)
				SELECT @PRCo, @EDLCode, @Amount, @Desc
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcLiab INTO @PRGroup, @PREndDate, @Employee, @PaySeq, @EDLCode, @Amount

	END

CLOSE bcLiab
DEALLOCATE bcLiab


/* Final selection for report */

--Detail rows for employees and pay sequences, used in report for counts
SELECT 
	'PRCo'				= a.PRCo,
	'PRGroup'			= a.PRGroup,
	'PREndDate'			= a.PREndDate,
	'RecId'				= a.RecId,
	'PREmployee'		= a.PREmployee,
	'PaySeq'			= a.PaySeq,
	'AddOnYN'			= a.AddOnYN,
	'EarnCode'			= a.EarnCode,
	'EarnAmt'			= a.EarnAmt,
	'EarnHours'			= a.EarnHours,
	'EarnRate'			= a.EarnRate,
	'EarnDescription'	= a.EarnDescription,
	'DedCode'			= a.DedCode,
	'DedAmt'			= a.DedAmt,
	'DedDescription'	= a.DedDescription,
	'DedType'			= a.DedType,
	'LiabCode'			= a.LiabCode,
	'LiabAmt'			= a.LiabAmt,
	'LiabDescription'	= a.LiabDescription,
	'TotEarnAmt'		= 0,
	'TotEarnHours'		= 0,
	'TotDedAmt'			= 0,
	'TotLiabAmt'		= 0,
	'PayMethod'			= PRSQ.PayMethod,
	'CMRef'				= PRSQ.CMRef,
	'ChkType'			= PRSQ.ChkType,
	'Processed'			= PRSQ.Processed,
	'LastName'			= PREH.LastName,
	'FirstName'			= PREH.FirstName,
	'MidName'			= PREH.MidName,
	'Suffix'			= PREH.Suffix,
	'SortName'			= PREH.SortName,
	'SSN'				= PREH.SSN,
	'JCCo'				= PREH.JCCo,
	'Job'				= PREH.Job,
	'JobDescription'	= JCJM.[Description],
	'CompanyName'		= HQCO.Name,
	'PaidDate'			= PRSQ.PaidDate,
	'ChkSort'			= PREH.ChkSort
FROM dbo.#a a
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON a.PRCo = PRSQ.PRCo AND a.PRGroup = PRSQ.PRGroup AND a.PREndDate = PRSQ.PREndDate AND a.PREmployee = PRSQ.Employee AND a.PaySeq = PRSQ.PaySeq
JOIN dbo.PREH PREH WITH(NOLOCK) ON a.PRCo = PREH.PRCo AND a.PREmployee = PREH.Employee
JOIN dbo.HQCO HQCO WITH(NOLOCK) ON a.PRCo = HQCO.HQCo
LEFT JOIN dbo.JCJM JCJM WITH(NOLOCK) ON PREH.JCCo = JCJM.JCCo AND PREH.Job = JCJM.Job

UNION

--Summary rows for Totals section
SELECT
	'PRCo'				= a.PRCo,
	'PRGroup'			= a.PRGroup,			--Always NULL
	'PREndDate'			= a.PREndDate,			--Always NULL
	'RecId'				= a.RecId,
	'PREmployee'		= 999999999,			--Out-of-range dummy Employee value allows Crystal to identify summary rows
	'PaySeq'			= a.PaySeq,				--Always NULL
	'AddOnYN'			= a.AddOnYN,
	'EarnCode'			= a.EarnCode,
	'EarnAmt'			= 0,
	'EarnHours'			= 0,
	'EarnRate'			= a.EarnRate,			--Always NULL
	'EarnDescription'	= a.EarnDescription,
	'DedCode'			= a.DedCode,
	'DedAmt'			= 0,
	'DedDescription'	= a.DedDescription,
	'DedType'			= a.DedType,
	'LiabCode'			= a.LiabCode,
	'LiabAmt'			= 0,
	'LiabDescription'	= a.LiabDescription,
	'TotEarnAmt'		= a.TotEarnAmt,
	'TotEarnHours'		= a.TotEarnHours,
	'TotDedAmt'			= a.TotDedAmt,
	'TotLiabAmt'		= a.TotLiabAmt,
	'PayMethod'			= NULL,
	'CMRef'				= NULL,
	'ChkType'			= NULL,
	'Processed'			= NULL,
	'LastName'			= NULL,
	'FirstName'			= NULL,
	'MidName'			= NULL,
	'Suffix'			= NULL,
	'SortName'			= NULL,
	'SSN'				= NULL,
	'JCCo'				= NULL,
	'Job'				= NULL,
	'JobDescription'	= NULL,
	'CompanyName'		= HQCO.Name,
	'PaidDate'			= NULL,
	'ChkSort'			= NULL
FROM dbo.#a a
JOIN dbo.HQCO HQCO WITH(NOLOCK) ON a.PRCo = HQCO.HQCo
WHERE a.PREmployee IS NULL						--Identifies summary rows in table #a

ORDER BY
	a.PRCo,
	a.PRGroup,
	a.PREndDate,
	a.PREmployee,
	a.PaySeq,
	a.RecId


IF object_id('tempdb..#a') IS NOT NULL
BEGIN
   DROP TABLE dbo.#a
END
GO
GRANT EXECUTE ON  [dbo].[brptPRRegisterTotals] TO [public]
GO
