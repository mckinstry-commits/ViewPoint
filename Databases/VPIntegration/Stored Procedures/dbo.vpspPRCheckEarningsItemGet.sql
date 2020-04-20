SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPRCheckEarningsItemGet]
/************************************************************
* CREATED:     SDE 6/7/2006
* MODIFIED:    Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
*
* USAGE:
*   Returns the PR Check Earnings for a given PRCo and Employee
*	Joins PREC for the EarnCode Description
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PRCo, PRGroup, PREndDate, Employee, PaySeq         
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee, @PaySeq tinyint )
AS
	SET NOCOUNT ON;


select PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.Employee, PRDT.PaySeq, PRDT.EDLType, PRDT.EDLCode, PRDT.Hours, PRDT.Amount, 
	PRDT.SubjectAmt, PRDT.EligibleAmt, PRDT.UseOver, PRDT.OverAmt, PRDT.OverProcess, PRDT.VendorGroup, PRDT.Vendor, PRDT.APDesc,
	PRDT.OldHours, PRDT.OldAmt, PRDT.OldSubject, PRDT.OldEligible, PRDT.OldMth, PRDT.OldVendor, PRDT.OldAPMth, PRDT.OldAPAmt, 
	PRDT.UniqueAttchID, PREC.Description, PRDT.KeyID

from PRDT with (nolock) 

left join PREC with (nolock) on PRDT.PRCo = PREC.PRCo and PRDT.EDLCode = PREC.EarnCode

where PRDT.PRCo = @PRCo and PRDT.Employee = @Employee and PRDT.PREndDate = @PREndDate and PRDT.EDLType = 'E'


GO
GRANT EXECUTE ON  [dbo].[vpspPRCheckEarningsItemGet] TO [VCSPortal]
GO
