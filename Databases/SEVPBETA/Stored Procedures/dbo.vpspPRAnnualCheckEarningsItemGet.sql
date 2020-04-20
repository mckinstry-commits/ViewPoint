SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPRAnnualCheckEarningsItemGet]
/************************************************************
* CREATED:     SDE 6/8/2006
* MODIFIED:    chs 8/30/2006
* MODIFIED:	   chs 9/28/06
* MODIFIED:	   chs 1/31/07
* MODIFIED:	   chs 5/1/07
* MODIFIED:    CJG 4/9/10 (Issue 139075 - Code throws error converting String to bDate for PaidYear but PaidYear is an int anyway)
* MODIFIED:    Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
*
* USAGE:
*   Returns the Annual PR Check Earnings for a given PRCo and Employee
*	Joins c for the EarnCode Description
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PRCo, PRGroup, PaidYear, Employee, PaySeq         
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PRCo bCompany, @PaidYear int, @Employee bEmployee)

AS
	SET NOCOUNT ON;

Select 
c.Description, 
c.KeyID,
sum(d.Amount)as 'YTDAmount', 
sum(d.Hours) as 'YTDHours'

from PRDT d with (nolock)
	join PRSQ s with (nolock) on s.PREndDate=d.PREndDate 
						and  d.PRCo=s.PRCo 
						and d.PRGroup = s.PRGroup 
						and d.Employee = s.Employee 
						and d.PaySeq = s.PaySeq
	left join PREC c with (nolock) on d.PRCo = c.PRCo 
						and d.EDLCode = c.EarnCode

where d.PRCo = @PRCo and d.Employee = @Employee
	and Year(s.PaidDate) = @PaidYear 
	and s.PayMethod <> 'X' and CMRef is not Null and d.EDLType ='E'

Group by
c.Description, c.KeyID








GO
GRANT EXECUTE ON  [dbo].[vpspPRAnnualCheckEarningsItemGet] TO [VCSPortal]
GO
