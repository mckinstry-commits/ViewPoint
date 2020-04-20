SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[brptPRRegister]
(
	@PRCo			tinyint,
	@PRGroup		tinyint,
	@PREndDate		smalldatetime,
	@SortOrder		varchar(1)		= 'A',
	@BeginSortName	varchar(20)		= '',
	@EndSortName	varchar(20)		= 'zzzzzzzzzzzzzzz',
	@BeginEmployee	int				= 0,
	@EndEmployee	int				= 999999,
	@BegChkSort		varchar(10)		= '',
	@EndChkSort		varchar(10)		= '~~~~~~~~~~'
)

AS

/**************************************************************************************

Author:			JRE
Date Created:	10/21/2000
Reports:		PR Payroll Register (PRRegister.rpt)

Purpose:		Returns earnings, deductions, and liabilities by Employee and Pay Seq
				for the specified PRCo, PRGroup, and PREndDate. Results may be
				restricted to specified ranges for employee sort name, employee number,
				or check print order value.

Revision History      
Date		Author	Issue	Description
09/05/2002	CR		-		Added parameters @BegChkSort, @EndChkSort, and field 
							ChkSort to the Union statement.
04/02/2003	ET		-		Fixed to make ansii standard for Crystal 9.0.
04/02/2003	ET		20721	Fixed concatenation.
09/16/2003	DH		22437	Printing too many Addons for Total records.
10/22/2004	DW		25879	Added WITH(NOLOCK).
12/16/2008	CWW		131437	Added data items BeginDate PREndDate from table PRPC to be 
							returned as smalldatetime. This data was being returned in 
							@daterange, however the date/string manipulations were not 
							working within the crystal reports for international date 
							formatting. The daterange variable was not changed.
09/08/2009	CWW		132166	Added logic to handle null paid dates.
09/25/2012	CUC		B-10717	Revised to handle deduction payback amounts; corrected
							parameter default values; removed extraneous and obsolete
							code (reduced execution time by 87%); corrected several
							minor defects; reformatted for legibility.
09/25/2012	CUC		137812	Revised final SELECT statement to return PRSQ.PaidDate
							unconditionally; updated related conditional logic in
							Crystal file.
09/25/2012	CUC		141045	For selection criteria using parameters @BegChkSort and
							@EndChkSort, added PRSQ.ChkSort (override) as first priority
							comparison value, before PREH.ChkSort (standard).
09/25/2012	CUC		143945	Deleted obsolete parameters @BeginJCCo and @EndJCCo from
							stored procedure, report file, and report metadata.
09/25/2012	CUC		145638	Changed default value for @EndChkSort to '~~~~~~~~~~'
							(ten count tilde characters) in stored procedure and Crystal
							file.

**************************************************************************************/

SET NOCOUNT ON


DECLARE @Employee bEmployee, @PaySeq tinyint, @EDLCode bEDLCode, @Amount bDollar, @Rate bUnitCost, @Hours bHrs
DECLARE @RecId int, @Desc bDesc, @PRPCBeginDate bDate


SELECT @PRPCBeginDate = BeginDate
FROM dbo.PRPC WITH(NOLOCK)
WHERE PRCo = @PRCo AND PRGroup = @PRGroup AND PREndDate = @PREndDate


/* Create temp table to hold values for final selection */

CREATE TABLE dbo.#a
(
	[RecId]				int	IDENTITY(1,1)	NOT NULL,
	[PRCo]				tinyint				NOT NULL,	--bCompany
	[PRGroup]			tinyint				NOT NULL,	--bCompany
	[PREndDate]			smalldatetime		NOT NULL,	--bDate
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
	([PREmployee], [PaySeq], [RecId])

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
SELECT					--Regular deductions
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'PREmployee'		= PRDT.Employee,
	'PaySeq'			= PRDT.PaySeq,
	'DedCode'			= PRDT.EDLCode,
	'DedAmt'			= CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END,
	'DedDescription'	= PRDL.[Description],
	'DedType'			= '1-RegularDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRDT.PRCo AND PREH.Employee = PRDT.Employee
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.Employee = PRDT.Employee AND PRSQ.PaySeq = PRDT.PaySeq
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo 
AND PRDT.PRGroup = @PRGroup 
AND PRDT.PREndDate = @PREndDate 
AND PRDT.EDLType = 'D'
AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
UNION
SELECT					--Payback deductions
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'PREmployee'		= PRDT.Employee,
	'PaySeq'			= PRDT.PaySeq,
	'DedCode'			= PRDT.EDLCode,
	'DedAmt'			= CASE WHEN PRDT.PaybackOverYN = 'Y' THEN PRDT.PaybackOverAmt ELSE PRDT.PaybackAmt END,
	'DedDescription'	= 'Payback - ' + ISNULL(PRDL.[Description],''),
	'DedType'			= '2-PaybackDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRDT.PRCo AND PREH.Employee = PRDT.Employee
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.Employee = PRDT.Employee AND PRSQ.PaySeq = PRDT.PaySeq
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo 
AND PRDT.PRGroup = @PRGroup 
AND PRDT.PREndDate = @PREndDate 
AND PRDT.EDLType = 'D'
AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
--Include payback row if there is a non-zero payback amount or if payback override flag is set
AND (PRDT.PaybackAmt <> 0 OR PRDT.PaybackOverYN = 'Y')
ORDER BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.Employee, PRDT.PaySeq, PRDT.EDLCode, DedType

/* Insert summary rows for Totals section */
/* Note that summary rows in table #a may later be identified as rows where PREmployee is null */

INSERT INTO dbo.#a
(
	[PRCo],
	[PRGroup],
	[PREndDate],
	[DedCode],
	[TotDedAmt],
	[DedDescription],
	[DedType]
)
SELECT					--Regular deductions
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'DedCode'			= PRDT.EDLCode,
	'TotDedAmt'			= SUM(CASE WHEN PRDT.UseOver='Y' THEN PRDT.OverAmt ELSE PRDT.Amount END),
	'DedDescription'	= PRDL.[Description],
	'DedType'			= '1-RegularDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRDT.PRCo AND PREH.Employee = PRDT.Employee
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.Employee = PRDT.Employee AND PRSQ.PaySeq = PRDT.PaySeq
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.PREndDate = @PREndDate
AND PRDT.EDLType = 'D'
AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
GROUP BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.EDLCode, PRDL.[Description]
UNION
SELECT					--Payback deductions
	'PRCo'				= PRDT.PRCo,
	'PRGroup'			= PRDT.PRGroup,
	'PREndDate'			= PRDT.PREndDate,
	'DedCode'			= PRDT.EDLCode,
	'TotDedAmt'			= SUM(CASE WHEN PRDT.PaybackOverYN = 'Y' THEN PRDT.PaybackOverAmt ELSE PRDT.PaybackAmt END),
	'DedDescription'	= 'Payback - ' + ISNULL(PRDL.[Description],''),
	'DedType'			= '2-PaybackDedn'
FROM dbo.PRDT PRDT WITH(NOLOCK)
JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRDT.PRCo AND PREH.Employee = PRDT.Employee
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.Employee = PRDT.Employee AND PRSQ.PaySeq = PRDT.PaySeq
LEFT JOIN dbo.PRDL PRDL WITH(NOLOCK) ON PRDT.PRCo = PRDL.PRCo AND PRDT.EDLCode = PRDL.DLCode
WHERE PRDT.PRCo = @PRCo
AND PRDT.PRGroup = @PRGroup
AND PRDT.PREndDate = @PREndDate
AND PRDT.EDLType = 'D'
AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
--Include payback row if there is a non-zero payback amount or if payback override flag is set
AND (PRDT.PaybackAmt <> 0 OR PRDT.PaybackOverYN = 'Y')
GROUP BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.EDLCode, PRDL.[Description]
ORDER BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.EDLCode, DedType


/* EARNINGS, Standard */
/* Update existing rows in temp table with standard earnings (from PRTH); or insert new rows if necessary */

DECLARE bcEarn CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRTH.Employee, PRTH.PaySeq, PRTH.EarnCode, PRTH.Amt, PRTH.[Hours], PRTH.Rate
	FROM dbo.PRTH PRTH WITH(NOLOCK)
	JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRTH.PRCo AND PREH.Employee = PRTH.Employee
	JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRTH.PRCo AND PRSQ.PRGroup = PRTH.PRGroup AND PRSQ.PREndDate = PRTH.PREndDate AND PRSQ.Employee = PRTH.Employee AND PRSQ.PaySeq = PRTH.PaySeq
	WHERE PRTH.PRCo = @PRCo
	AND PRTH.PRGroup = @PRGroup
	AND PRTH.PREndDate = @PREndDate
	AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
	AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
	AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
	ORDER BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.EarnCode, PRTH.Rate, PRTH.Employee, PRTH.PaySeq

OPEN bcEarn
FETCH NEXT FROM bcEarn INTO @Employee, @PaySeq, @EDLCode, @Amount, @Hours, @Rate

WHILE @@fetch_status = 0
	BEGIN

		SELECT @Desc = [Description] FROM dbo.PREC WITH(NOLOCK) WHERE PRCo = @PRCo AND EarnCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee = @Employee
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
				INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, EarnCode, TotEarnAmt, TotEarnHours, EarnDescription, AddOnYN)
				SELECT @PRCo, @PRGroup, @PREndDate, @EDLCode, @Amount, @Hours, @Desc, 'N'
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcEarn INTO @Employee, @PaySeq, @EDLCode, @Amount, @Hours, @Rate

	END

CLOSE bcEarn
DEALLOCATE bcEarn


/* EARNINGS, Add-on */
/* Update existing rows in temp table with add-on earnings (from PRTA); or insert new rows if necessary */

DECLARE bcPRTA CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRTA.Employee, PRTA.PaySeq, PRTA.EarnCode, PRTA.Amt, PRTA.Rate
	FROM dbo.PRTA PRTA WITH(NOLOCK)
	JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRTA.PRCo AND PREH.Employee = PRTA.Employee
	JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRTA.PRCo AND PRSQ.PRGroup = PRTA.PRGroup AND PRSQ.PREndDate = PRTA.PREndDate AND PRSQ.Employee = PRTA.Employee AND PRSQ.PaySeq = PRTA.PaySeq
	WHERE PRTA.PRCo=@PRCo
	AND PRTA.PRGroup = @PRGroup
	AND PRTA.PREndDate = @PREndDate
	AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
	AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
	AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
	ORDER BY PRTA.PRCo, PRTA.PRGroup, PRTA.PREndDate, PRTA.EarnCode, PRTA.Rate, PRTA.Employee, PRTA.PaySeq

OPEN bcPRTA
FETCH NEXT FROM bcPRTA INTO @Employee, @PaySeq, @EDLCode, @Amount, @Rate

WHILE @@fetch_status = 0
	BEGIN
	
		SELECT @Desc = [Description] FROM dbo.PREC WITH(NOLOCK) WHERE PRCo = @PRCo AND EarnCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee = @Employee
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
				INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, EarnCode, TotEarnAmt, EarnDescription, AddOnYN)
				SELECT @PRCo, @PRGroup, @PREndDate, @EDLCode, @Amount, @Desc, 'Y'
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcPRTA INTO @Employee, @PaySeq, @EDLCode, @Amount, @Rate

	END

CLOSE bcPRTA
DEALLOCATE bcPRTA


/* LIABILITIES */
/* Update existing rows in temp table with liabilities (from PRDT); or insert new rows if necessary */
     
DECLARE bcLiab CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRDT.Employee, PRDT.PaySeq, PRDT.EDLCode, LiabilityAmount = (CASE WHEN PRDT.UseOver = 'Y' THEN PRDT.OverAmt ELSE PRDT.Amount END)
	FROM dbo.PRDT PRDT WITH(NOLOCK)
	JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = PRDT.PRCo AND PREH.Employee = PRDT.Employee
	JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = PRDT.PRCo AND PRSQ.PRGroup = PRDT.PRGroup AND PRSQ.PREndDate = PRDT.PREndDate AND PRSQ.Employee = PRDT.Employee AND PRSQ.PaySeq = PRDT.PaySeq
	WHERE PRDT.PRCo = @PRCo
	AND PRDT.PRGroup = @PRGroup
	AND PRDT.PREndDate = @PREndDate
	AND PRDT.EDLType = 'L'
	AND PREH.SortName BETWEEN @BeginSortName AND @EndSortName
	AND PREH.Employee BETWEEN @BeginEmployee AND @EndEmployee
	AND ISNULL(PRSQ.ChkSort,ISNULL(PREH.ChkSort,'')) BETWEEN @BegChkSort AND @EndChkSort
	ORDER BY PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.EDLCode, PRDT.Employee, PRDT.PaySeq

OPEN bcLiab
FETCH NEXT FROM bcLiab INTO @Employee, @PaySeq, @EDLCode, @Amount

WHILE @@fetch_status = 0
	BEGIN

		SELECT @Desc = [Description] FROM dbo.PRDL WITH(NOLOCK) WHERE PRCo = @PRCo AND DLCode = @EDLCode
		
		/* Update or insert detail rows for employees and pay sequences */

		SELECT @RecId = MIN(RecId) FROM dbo.#a
		WHERE PREmployee = @Employee 
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
		WHERE PREmployee IS NULL --Identifies summary rows in table #a
		AND (LiabCode IS NULL OR LiabCode = @EDLCode)

		IF @RecId IS NOT NULL
			BEGIN
				UPDATE dbo.#a
				SET LiabCode = @EDLCode, TotLiabAmt = ISNULL(TotLiabAmt,0)+@Amount, LiabDescription = @Desc
				WHERE RecId = @RecId
			END
		ELSE
			BEGIN
				INSERT INTO dbo.#a (PRCo, PRGroup, PREndDate, LiabCode, TotLiabAmt, LiabDescription)
				SELECT @PRCo, @PRGroup, @PREndDate, @EDLCode, @Amount, @Desc
			END

		/* Retrieve next row from cursor */
		FETCH NEXT FROM bcLiab INTO @Employee, @PaySeq, @EDLCode, @Amount

	END

CLOSE bcLiab
DEALLOCATE bcLiab


/* Final selection for report */

--Detail rows for employees and pay sequences
SELECT 
	'PRCo'				= a.PRCo,
	'PRGroup'			= a.PRGroup,
	'GroupDescription'	= PRGR.[Description],
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
	'SortOrder'			= CASE @SortOrder
							WHEN 'A' THEN PREH.SortName
							WHEN 'J' THEN CONVERT(varchar(6),100000+PREH.JCCo) + ISNULL(PREH.Job,'')
							ELSE CONVERT(varchar(10),100000000+a.PREmployee) END,
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
	'PRPCBeginDate'		= @PRPCBeginDate,
	'JobDescription'	= JCJM.[Description],
	'CompanyName'		= HQCO.Name,
	'PaidDate'			= PRSQ.PaidDate,
	'ChkSort'			= PREH.ChkSort
FROM dbo.#a a
JOIN dbo.PRSQ PRSQ WITH(NOLOCK) ON PRSQ.PRCo = a.PRCo AND PRSQ.PRGroup = a.PRGroup AND PRSQ.PREndDate = a.PREndDate AND PRSQ.Employee = a.PREmployee AND PRSQ.PaySeq = a.PaySeq
JOIN dbo.PREH PREH WITH(NOLOCK) ON PREH.PRCo = a.PRCo AND PREH.Employee = a.PREmployee
JOIN dbo.PRGR PRGR WITH(NOLOCK) ON PRGR.PRCo = a.PRCo AND PRGR.PRGroup = a.PRGroup
JOIN dbo.HQCO HQCO WITH(NOLOCK) ON HQCO.HQCo = a.PRCo
LEFT JOIN dbo.JCJM JCJM WITH(NOLOCK) ON JCJM.JCCo = PREH.JCCo AND JCJM.Job = PREH.Job

UNION

--Summary rows for Totals section
SELECT
	'PRCo'				= a.PRCo,
	'PRGroup'			= a.PRGroup,
	'GroupDescription'	= PRGR.[Description],
	'PREndDate'			= a.PREndDate,
	'RecId'				= a.RecId,
	'PREmployee'		= 999999999,	--Out-of-range dummy Employee value allows Crystal to identify summary rows
	'PaySeq'			= NULL,
	'AddOnYN'			= a.AddOnYN,
	'EarnCode'			= a.EarnCode,
	'EarnAmt'			= 0,
	'EarnHours'			= 0,
	'EarnRate'			= a.EarnRate,
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
	'SortOrder'			= 'zzzzzzzzzz',	--Insures that Crystal group sort will always order summary rows after detail rows
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
	'PRPCBeginDate'		= @PRPCBeginDate,
	'JobDescription'	= NULL,
	'CompanyName'		= HQCO.Name,
	'PaidDate'			= NULL,
	'ChkSort'			= NULL
FROM dbo.#a a
JOIN dbo.PRGR PRGR WITH(NOLOCK) ON PRGR.PRCo = a.PRCo AND PRGR.PRGroup = a.PRGroup
JOIN dbo.HQCO HQCO WITH(NOLOCK) ON HQCO.HQCo = a.PRCo
WHERE a.PREmployee IS NULL				--Identifies summary rows in table #a

ORDER BY
	CASE @SortOrder
			WHEN 'A' THEN PREH.SortName
			WHEN 'J' THEN CONVERT(varchar(6),100000+PREH.JCCo) + ISNULL(PREH.Job,'')
			ELSE CONVERT(varchar(10),100000000+a.PREmployee) END,
	a.PREmployee,
	a.PaySeq,
	a.RecId


IF object_id('tempdb..#a') IS NOT NULL
BEGIN
   DROP TABLE dbo.#a
END
GO
GRANT EXECUTE ON  [dbo].[brptPRRegister] TO [public]
GO
