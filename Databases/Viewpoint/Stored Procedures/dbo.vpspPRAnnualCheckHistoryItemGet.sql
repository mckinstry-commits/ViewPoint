SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.vpspPRAnnualCheckHistoryItemGet
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    chs	9/28/06
* MODIFIED:		chs 1/31/07
* MODIFIED:    Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
*
* USAGE:
*   Returns the Annual PR Check History for a given PRCo and Employee
*	
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PRCo, Employee        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PRCo bCompany, @Employee bEmployee)
AS
	SET NOCOUNT ON;


/*
Select DISTINCT c.PRCo, 
c.Employee, 
Year(c.PaidDate) as 'PaidYear', 
sum(c.Earnings) as 'YTDEarnings', 
Sum(c.Dedns) as 'YTDDedns', 
sum(c.Hours) as 'YTDHours',
sum(c.Earnings) - Sum(c.Dedns) as 'NetAmount'

from PRSQ c

Where c.PRCo = @PRCo and c.Employee = @Employee and c.PayMethod <> 'X' and c.CMRef is not Null

Group by Year(c.PaidDate), c.PRCo, c.Employee  
order by Year(c.PaidDate) Desc
*/


Select 
PRCo, 
Employee, 
PaidYear, 
YTDEarnings, 
YTDDedns, 
YTDHours,
NetAmount,
KeyID

from pvPRAnnualCheckHistory 

Where PRCo = @PRCo and Employee = @Employee 

Order by PaidYear Desc
GO
GRANT EXECUTE ON  [dbo].[vpspPRAnnualCheckHistoryItemGet] TO [VCSPortal]
GO
