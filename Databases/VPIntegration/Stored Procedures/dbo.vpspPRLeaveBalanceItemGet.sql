SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE  PROCEDURE [dbo].[vpspPRLeaveBalanceItemGet]
/************************************************************
* CREATED:     SDE 6/13/2006
* MODIFIED:		6/7/07	CHS 
*
* USAGE:
*   Returns the PR Leave Balance for a given PRCo and Employee
*	Joins PRLV for Leave Description and HQUM for Unit of Measure Description
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

select PRLV.KeyID, PRLV.Description, IsNull(PREL.CarryOver, PRLV.CarryOver) as 'CarryOver', PREL.AvailBal, PREL.LeaveCode, HQUM.Description as 'UnitDesc' 

from PREL with (nolock)

left Join PRLV with (nolock) on PREL.PRCo = PRLV.PRCo and PREL.LeaveCode = PRLV.LeaveCode

left Join HQUM with (nolock) on PRLV.UM = HQUM.UM

where PREL.PRCo = @PRCo and Employee = @Employee










GO
GRANT EXECUTE ON  [dbo].[vpspPRLeaveBalanceItemGet] TO [VCSPortal]
GO
