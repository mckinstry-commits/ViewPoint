SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------
----------------------------------------------------------------------
/*

Author:			Mike Brewer
Create date:	6/15/2010
Description:	Procedure for PR Canada PD7A INformation Report
Clientele:		Issue #135757

-------------------------------

Revision 
Author:			Czeslaw Czapla
Revision date:	2011-0401
Clientele:		143752
VersionOne:		D-01460

Primary changes: Added view PRSQ to joins and changed date range selection criteria so that
PRSQ.PaidDate is used instead of PRDT.PREndDate. This provides two benefits: it permits
specification of paid date values on launcher as report parameter input values (as desired); 
it effectively excludes from the result set any rows in PRDT whose related rows in PRSQ contain null values
for PaidDate (in other words, if an employee has not been paid, thus PRSQ.PaidDate is null, then 
payroll data for that employee, for the relevant pay period, is now excluded from the aggregate sums 
calculated by the stored procedure). Added selection criterion (PRSQ.CMRef IS NOT NULL) to exclude rows
from result set that reflect paychecks that were issued and later voided (the void action nullifies 
PRSQ.CMRef, but does not nullify PRSQ.PaidDate); payroll data for such voided paychecks should be
excluded from the result set for this report.

Additional changes: Reformatted SQL code for improved readability and maintainability; 
corrected defective test for NULL on @TaxDeductions; added SET NOCOUNT OFF at end; 
in COUNT(DISTINCT Employee) query, changed from LEFT OUTER JOIN to INNER JOIN, since PREC.TrueEarns 
selection criterion had already created de facto INNER JOIN for query; removed view HQCO from joins,
since extraneous and meaningless (was not referenced in any Select clause or From clause, and had
no functional effect on result set); deleted aliases whose names were identical to names of views
that they referenced; changed names assigned to columns in AS clauses so that column names now include 
no spaces and no hyphens.

-------------------------------

Revision 
Author:			Czeslaw Czapla
Revision date:	2012-0120
Clientele:		145556
VersionOne:		D-04285

Changes:
1. For sum @TaxDedns, restricted addend amounts to EDLType 'D' or 'L' (effectively excluding EDLType 'E').
2. Refactored main query to eliminate redundant statements for calculating @CPPTotal, @EITotal, @Remittance.
3. For sums @TaxDedns, @CPPEmployee, @CPPCompany, @EIEmployee, @EICompany, added nested case statement to use 
OverAmt (instead of Amount) whenever two relevant flags (UseOver; OverProcess) are set (in order to report 
qualified override amounts when present, instead of original calculated amounts).
4. For count @CountPaidEmployees, changed selection criteria to restrict records to only the last pay period 
(MAX(PREndDate)) within the remitting period, per CRA requirements.

-------------------------------

Revision 
Author:			Czeslaw Czapla
Revision date:	2012-1107; 2012-1109
Clientele:		147472
VersionOne:		B-10768; D-06170

Changes:
1. For sum @TaxDedns, changed target datatype in CONVERT function from varchar(3) to varchar(5), because 
expression (EDLCode) has datatype smallint (numeric(5,0)); possibly, expression (EDLCode) previously had
datatype tinyint (numeric(3,0)) in the table definition.

*/
----------------------------------------------------------------------
----------------------------------------------------------------------

CREATE PROCEDURE [dbo].[brptPD7A]
	@PRCo				bCompany,
	@BeginDate			bDate,
	@EndDate			bDate,
	@CPP_Emp_DLCode		bEDLCode,
	@CPP_Comp_DLCode	bEDLCode,
	@EI_Emp_DLCode		bEDLCode,
	@EI_Comp_DLCode		bEDLCode,
	@TaxDeductions		varchar(200)

AS

BEGIN

SET NOCOUNT ON


--Use variable statements below for testing purposes

--DECLARE @PRCo bCompany
--SET @PRCo = 205

--DECLARE @BeginDate DATETIME 
--SET @BeginDate = '2010-01-01'

--DECLARE @EndDate DATETIME 
--SET @EndDate = '2010-06-15'

--DECLARE @CPP_Emp_DLCode INT
--SET @CPP_Emp_DLCode = 1

--DECLARE @CPP_Comp_DLCode INT
--SET @CPP_Comp_DLCode = 50 

--DECLARE @EI_Emp_DLCode INT
--SET @EI_Emp_DLCode = 2

--DECLARE @EI_Comp_DLCode INT
--SET @EI_Comp_DLCode = 51 

--DECLARE @TaxDeductions VARCHAR(200)
--SET @TaxDeductions = '3' 


-- If @TaxDeductions report input parameter is not empty string and is not null
-- then wrap value in comma characters to facilitate CHARINDEX comparison below

IF ISNULL(@TaxDeductions,'') = ''
	BEGIN
		SET @TaxDeductions = NULL
	END
ELSE
	BEGIN
		SET @TaxDeductions = ',' + @TaxDeductions + ',' 
	END


DECLARE	@tableMain TABLE (
	PRCo		bCompany, 
	PRGroup		bGroup, 
	PREndDate	bDate, 
	Employee	bEmployee, 
	PaySeq		tinyint, 
	EDLType		char(1), 
	EDLCode		bEDLCode, 
	Amount		bDollar, 
	UseOver		bYN, 
	OverProcess	bYN, 
	OverAmt		bDollar, 
	TrueEarns	bYN			NULL, 
	PaidDate	bDate		NULL, 
	CMRef		bCMRef		NULL
)


INSERT INTO @tableMain (
		PRCo, PRGroup, PREndDate, Employee, PaySeq, 
		EDLType, EDLCode, Amount, UseOver, OverProcess, 
		OverAmt, TrueEarns, PaidDate, CMRef
)
SELECT	PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.Employee, PRDT.PaySeq, 
		PRDT.EDLType, PRDT.EDLCode, PRDT.Amount, PRDT.UseOver, PRDT.OverProcess, 
		PRDT.OverAmt, PREC.TrueEarns, PRSQ.PaidDate, PRSQ.CMRef
FROM	PRDT
		INNER JOIN
		PRSQ ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
		LEFT OUTER JOIN
		PREC ON PRDT.PRCo = PREC.PRCo AND PRDT.EDLCode = PREC.EarnCode
WHERE	PRDT.PRCo = @PRCo
AND		PRSQ.PaidDate BETWEEN @BeginDate AND @EndDate 
AND		PRSQ.CMRef IS NOT NULL


DECLARE	@LastPREndDate		bDate
DECLARE	@GrossPayroll		bDollar
DECLARE	@CountPaidEmployees	int
DECLARE	@TaxDedns			bDollar
DECLARE	@CPPEmployee		bDollar
DECLARE	@CPPCompany			bDollar
DECLARE	@CPPTotal			bDollar
DECLARE	@EIEmployee			bDollar
DECLARE	@EICompany			bDollar
DECLARE	@EITotal			bDollar
DECLARE	@Remittance			bDollar


SELECT

	@GrossPayroll =
	SUM(
		CASE
			WHEN (EDLType = 'E' AND TrueEarns = 'Y') THEN Amount 
			ELSE 0 
		END
	),

	@TaxDedns = 
	SUM(
		CASE
			WHEN (EDLType IN ('D','L') AND CHARINDEX(','+CONVERT(varchar(5),EDLCode)+',',@TaxDeductions) > 0) THEN 
				CASE
					WHEN (UseOver = 'Y' AND OverProcess = 'Y') THEN OverAmt
					ELSE Amount
				END
			ELSE 0
		END
	), 

	@CPPEmployee =  
	SUM(
		CASE
			WHEN (EDLType = 'D' AND EDLCode = @CPP_Emp_DLCode) THEN 
				CASE
					WHEN (UseOver = 'Y' AND OverProcess = 'Y') THEN OverAmt
					ELSE Amount
				END
			ELSE 0
		END
	), 
 
	@CPPCompany =
	SUM(
		CASE
			WHEN (EDLType = 'L' AND EDLCode = @CPP_Comp_DLCode) THEN 
				CASE
					WHEN (UseOver = 'Y' AND OverProcess = 'Y') THEN OverAmt
					ELSE Amount
				END
			ELSE 0
		END
	), 

	@CPPTotal = @CPPEmployee + @CPPCompany,

	@EIEmployee =
	SUM(
		CASE
			WHEN (EDLType = 'D' AND EDLCode = @EI_Emp_DLCode) THEN 
				CASE
					WHEN (UseOver = 'Y' AND OverProcess = 'Y') THEN OverAmt
					ELSE Amount
				END
			ELSE 0
		END
	), 

	@EICompany =
	SUM(
		CASE
			WHEN (EDLType = 'L' AND EDLCode = @EI_Comp_DLCode) THEN 
				CASE
					WHEN (UseOver = 'Y' AND OverProcess = 'Y') THEN OverAmt
					ELSE Amount
				END
			ELSE 0
		END
	),

	@EITotal = @EIEmployee + @EICompany,

	@Remittance = @TaxDedns + @CPPTotal + @EITotal

FROM	@tableMain


/* 
Employee count is a tally of employees paid for the last pay period of the remitting period.
The remitting period is defined as the time span between the Beginning Paid Date and 
the Ending Paid Date, inclusively.
*/


SELECT @LastPREndDate = MAX(PREndDate) FROM @tableMain


SELECT @CountPaidEmployees = 
	(
		SELECT	COUNT(DISTINCT PRDT.Employee)
		FROM	PRDT
				INNER JOIN
				PRSQ ON PRDT.PRCo = PRSQ.PRCo AND PRDT.PRGroup = PRSQ.PRGroup AND PRDT.PREndDate = PRSQ.PREndDate AND PRDT.Employee = PRSQ.Employee AND PRDT.PaySeq = PRSQ.PaySeq
				INNER JOIN
				PREC ON PRDT.PRCo = PREC.PRCo AND PRDT.EDLCode = PREC.EarnCode 
		WHERE	PRDT.PRCo = @PRCo
		AND		PRDT.EDLType = 'E' 
		AND		PREC.TrueEarns = 'Y'
		AND		PRDT.PREndDate = @LastPREndDate
		AND		PRSQ.CMRef IS NOT NULL
	)


/* FINAL SELECT statement */

SELECT	@GrossPayroll		AS 'GrossPayroll',
		@CountPaidEmployees	AS 'CountPaidEmployees',
		@TaxDedns			AS 'TaxDedns',
		@CPPEmployee		AS 'CPPEmployee',
		@CPPCompany			AS 'CPPCompany',
		@CPPTotal			AS 'CPPTotal',
		@EIEmployee			AS 'EIEmployee',
		@EICompany			AS 'EICompany',
		@EITotal			AS 'EITotal',
		@Remittance			AS 'Remittance'


SET NOCOUNT OFF

END
GO
GRANT EXECUTE ON  [dbo].[brptPD7A] TO [public]
GO
