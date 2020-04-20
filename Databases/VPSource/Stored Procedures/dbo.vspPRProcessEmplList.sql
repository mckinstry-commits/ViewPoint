SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRProcessEmplList]
/************************************************************************
* Created:	GG 01/25/07   
* Modified:    
*
* Usage:
*   Returns a list of employees that will be skipped by the payroll processing
*	procedures because they have entries in a timecard batch.
*
* Inputs:
*	@prco		PR Company #
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*
* Outputs:
*	resultset of employees with entries in bPRTB
*
*************************************************************************/
    
    (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null)

as
set nocount on

select distinct b.Employee, isnull(h.LastName,'') + ', ' + isnull(h.FirstName,'')
	+ ' ' + isnull(h.MidName,'') + ' ' + isnull(h.Suffix,'') as [Name],	b.BatchId, c.InUseBy
from dbo.bPRTB b (nolock)
join dbo.HQBC c (nolock) on b.Co = c.Co and b.Mth = c.Mth and b.BatchId = c.BatchId
join dbo.bPREH h (nolock) on b.Co = h.PRCo and b.Employee = h.Employee
where c.Co = @prco and c.PRGroup = @prgroup and c.PREndDate = @prenddate
order by b.Employee, b.BatchId

return

GO
GRANT EXECUTE ON  [dbo].[vspPRProcessEmplList] TO [public]
GO
