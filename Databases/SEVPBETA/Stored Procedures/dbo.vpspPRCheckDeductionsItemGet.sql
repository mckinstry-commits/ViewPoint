SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  PROCEDURE [dbo].[vpspPRCheckDeductionsItemGet]
/************************************************************
* CREATED:     SDE 6/7/2006
* MODIFIED:    CJG 9/3/2010 Issue 138199 - Pull correct amount when PRDT.UserOver is Y
*			   Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
*
* USAGE:
*   Returns the PR Check Deductions for a given PRCo and Employee
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
(@PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee, @PaySeq tinyint)
AS
	SET NOCOUNT ON;

select PRDT.PRCo, PRDT.PRGroup, PRDT.PREndDate, PRDT.Employee, PRDT.PaySeq, PRDT.EDLType, PRDT.EDLCode, PRDT.Hours, 
	case when PRDT.UseOver='Y' then PRDT.OverAmt else PRDT.Amount end AS Amount, 
	PRDT.SubjectAmt, PRDT.EligibleAmt, PRDT.UseOver, PRDT.OverAmt, PRDT.OverProcess, PRDT.VendorGroup, PRDT.Vendor, PRDT.APDesc,
	PRDT.OldHours, PRDT.OldAmt, PRDT.OldSubject, PRDT.OldEligible, PRDT.OldMth, PRDT.OldVendor, PRDT.OldAPMth, PRDT.OldAPAmt, 
	PRDT.UniqueAttchID, PRDL.Description, PRDT.KeyID

from PRDT with (nolock) 

left join PRDL with (nolock) on PRDT.PRCo = PRDL.PRCo and PRDT.EDLCode = PRDL.DLCode

where PRDT.PRCo = @PRCo and PRDT.Employee = @Employee and PRDT.PREndDate = @PREndDate and PRDT.EDLType = 'D'



GO
GRANT EXECUTE ON  [dbo].[vpspPRCheckDeductionsItemGet] TO [VCSPortal]
GO
