SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPRAnnualCheckDeductionsItemGet]
/************************************************************
* CREATED:     SDE 6/9/2006
* MODIFIED:    chs 9/28/06
* MODIFIED:		chs 1/31/07
* MODIFIED:		chs 3/07/07
* MODIFIED:    CJG 4/9/10 (Issue 139075 - Code throws error converting String to bDate for PaidYear but PaidYear is an int anyway)
* MODIFIED:    Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
*
* USAGE:
*   Returns the Annual PR Check Deductions for a given PRCo and Employee
*	Joins PRDL for the Deduction Description
*	
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
		--@PRGroup bGroup, @PaySeq tinyint )
		
		
AS
	SET NOCOUNT ON;

Select d.PRCo, d.Employee, 
d.EDLType, d.EDLCode, c.Description, c.KeyID,
Year(s.PaidDate) as 'PaidYear',
sum(d.Amount)as 'YTDAmount' 

from PRDT d
	join PRSQ s on s.PREndDate=d.PREndDate 
			and d.PRCo=s.PRCo 
			and d.PRGroup = s.PRGroup 
			and d.Employee = s.Employee 
			and d.PaySeq = s.PaySeq
	left join PRDL c with (nolock) on d.PRCo = c.PRCo and d.EDLCode = c.DLCode

where d.PRCo = @PRCo and d.Employee = @Employee 
	and Year(s.PaidDate) = @PaidYear 
	and s.PayMethod <> 'X' and CMRef is not Null and d.EDLType ='D'

Group by Year(s.PaidDate), d.PRCo, d.Employee, d.EDLType, d.EDLCode, c.Description, c.KeyID





GO
GRANT EXECUTE ON  [dbo].[vpspPRAnnualCheckDeductionsItemGet] TO [VCSPortal]
GO
