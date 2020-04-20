SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE  PROCEDURE [dbo].[vpspPRCheckHistoryItemGet]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    
*
* USAGE:
*   Returns the PR Check History for a given PRCo and Employee
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
(@PRCo bCompany, @Employee bEmployee, @KeyID int = Null)
AS
	SET NOCOUNT ON;

select PRCo, CMCo, CMAcct, PayMethod,
	case PayMethod when 'C' then 'Check' when 'E' then 'EFT' end as 'PayMethodDesc', 
	CMRef, CMRefSeq, EFTSeq, PRGroup, PREndDate, Employee, PaySeq, ChkType, 
	case ChkType when 'C' then 'Computer' when 'M' then 'Manual' end as 'ChkTypeDesc',
	PaidDate, PaidMth, Hours, Earnings, Dedns, PaidAmt, NonTrueAmt, Void, VoidMemo, Purge, PRPH.KeyID

from PRPH with (nolock) 

where PRCo = @PRCo and Employee = @Employee and Void = 'N' --and i.KeyID = IsNull(@KeyID, i.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspPRCheckHistoryItemGet] TO [VCSPortal]
GO
