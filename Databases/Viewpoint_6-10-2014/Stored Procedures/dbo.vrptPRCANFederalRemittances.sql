SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE	[dbo].[vrptPRCANFederalRemittances](		
	@Company			int,
	@BeginDate			bDate,
	@EndDate			bDate,
	@CPPCode			int,
	@CPPMatchCode		int,
	@EICode				int,
	@EIMatchCode		int,
	@FedTaxCode			int
)

AS

/******************************************************************************

Copyright 2013 Viewpoint Construction Software. All rights reserved.

CREATED:	DKOSLICKI 06/10/2010    
MODIFIED:	Issue 139999 - Provincial taxes not included in the report.  
            JayR 5/17/2013 Copyright symbol kills database compares.  

Reports:  PRCANFederalRemittances.RPT
Purpose:  Return the taxes (deductions and liabilities) contributed per employee

-------------------------------

Revision 
Author:			Czeslaw Czapla
Revision date:	2012-0202
Clientele:		145543
VersionOne:		D-04278

Changes:
1. Changed parameter name from @BegPREndingDate to @BeginDate; changed parameter name 
from @EndPREndingDate to @EndDate.
2. Moved parameter @BeginDate from ordinal position 7 to ordinal position 2; 
moved parameter @EndDate from ordinal position 8 to ordinal position 3.
3. Added case statement in SELECT to use PRDT.OverAmt instead of PRDT.Amount conditionally 
(in order to use override deduction or liability amounts when available).
4. Deleted PRDT.PREndDate from GROUP BY clause because extraneous.
5. Added inner join to view PRSQ; changed selection criteria from PRDT.PREndDate to PRSQ.PaidDate; 
added selection criterion to exclude rows where PRSQ.CMRef is null (deliberately excluding 
payroll data for pay sequences that are unpaid).

******************************************************************************/

SELECT Piv.*

FROM (
	SELECT	PRCo		= PD.PRCo,
		PRGroupDispValue	= PD.PRGroup,
		CoDescr		= HC.Name,
		EmployeeID	= PE.Employee,
		EmployeeLastName = PE.LastName,
		EDLCode		= CASE 	WHEN PD.EDLCode = @CPPCode		THEN 'CPPC'
					WHEN PD.EDLCode = @CPPMatchCode	THEN 'CPPMC'
					WHEN PD.EDLCode = @EICode		THEN 'EIC'
					WHEN PD.EDLCode = @EIMatchCode	THEN 'EIMC'
					WHEN PD.EDLCode = @FedTaxCode	THEN 'FTC'
					ELSE 'PTC' 
				END,
		Amount		= CASE WHEN PD.UseOver = 'Y' AND PD.OverProcess = 'Y' THEN SUM(ISNULL(PD.OverAmt,0))
					ELSE SUM(ISNULL(PD.Amount,0))
				END
					
	FROM		dbo.PRDT PD

	INNER JOIN	dbo.PRSQ PS
		ON	PD.PRCo = PS.PRCo AND PD.PRGroup = PS.PRGroup AND PD.PREndDate = PS.PREndDate AND PD.Employee = PS.Employee AND PD.PaySeq = PS.PaySeq

	LEFT JOIN	dbo.HQCO HC 
		ON	HC.HQCo = PD.PRCo

	LEFT JOIN	dbo.PREH PE 
		ON	PE.PRCo = PD.PRCo
		AND	PE.Employee = PD.Employee
	
	WHERE	PD.PRCo = @Company
		AND	(PD.EDLCode IN (	@CPPCode,
								@CPPMatchCode,
								@EICode,
								@EIMatchCode,
								@FedTaxCode)
			OR PD.EDLCode IN (	SELECT	SI.TaxDedn 
								FROM	PRSI SI 
								WHERE	SI.PRCo = @Company))
		AND PD.EDLType	 IN 	('D','L')
		AND	(PS.PaidDate 	>= 	@BeginDate OR @BeginDate = '1/1/1950')
		AND	(PS.PaidDate 	<= 	@EndDate OR @EndDate = '12/31/2050')
		AND PS.CMRef IS NOT NULL

	GROUP BY 	PD.PRCo,
			PD.PRGroup,
			HC.Name,
			PE.Employee,
			PE.LastName,
			PD.EDLCode,
			PD.UseOver,
			PD.OverProcess
			
	) AS A

PIVOT (SUM(A.Amount) FOR EDLCode IN ([CPPC],[CPPMC],[EIC],[EIMC],[FTC],[PTC])) AS Piv	

	
GO
GRANT EXECUTE ON  [dbo].[vrptPRCANFederalRemittances] TO [public]
GO
