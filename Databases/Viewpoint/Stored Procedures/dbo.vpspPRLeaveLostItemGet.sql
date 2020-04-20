SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE  PROCEDURE [dbo].[vpspPRLeaveLostItemGet]
/************************************************************
* CREATED:     SDE 6/13/2006
* MODIFIED:    
*
* USAGE:
*   Returns the PR Leave Lost for a given PRCo and Employee and LeaveCode
*	Joins HQUM for Unit Description
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PRCo, Employee, LeaveCode        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PRCo bCompany, @Employee bEmployee, @LeaveCode bLeaveCode)
AS
	SET NOCOUNT ON;

select PRLH.Description, PRLH.ActDate, PRLH.Amt, HQUM.Description as 'UnitDesc'

from PRLH with (nolock)

left Join PRLV with (nolock) on PRLH.PRCo = PRLV.PRCo and PRLH.LeaveCode = PRLV.LeaveCode

left Join HQUM with (nolock) on PRLV.UM = HQUM.UM

where PRLH.PRCo = @PRCo and Employee = @Employee and Type='R' and PRLH.LeaveCode = @LeaveCode












GO
GRANT EXECUTE ON  [dbo].[vpspPRLeaveLostItemGet] TO [VCSPortal]
GO
