SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRAutoEarnsEmplList]
/************************************************************************
* Created:	GG 01/31/07   
* Modified:    
*
* Usage:
*   Returns a list of active employees that will be skipped when posting auto 
*	earnings because they have entries in a timecard batch.
*
* Inputs:
*	@prco		PR Company #
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*
* Outputs:
*	resultset of active employees with auto earnings and entries in bPRTB
*
*************************************************************************/
    
    (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null)

as
set nocount on

select distinct b.Employee, isnull(h.LastName,'') + ', ' + isnull(h.FirstName,'')
	+ ' ' + isnull(h.MidName,'') + ' ' + isnull(h.Suffix,'') as [Name],	b.BatchId, c.InUseBy
from dbo.bPRTB b (nolock)
join dbo.bPREH h (nolock) on b.Co = h.PRCo and b.Employee = h.Employee
join dbo.bPRAE a (nolock) on b.Co = a.PRCo and b.Employee = a.Employee
join dbo.bHQBC c (nolock) on b.Co = c.Co and b.Mth = c.Mth and b.BatchId = c.BatchId
where c.Co = @prco and c.PRGroup = @prgroup and c.PREndDate = @prenddate
	and h.ActiveYN = 'Y'
order by b.Employee, b.BatchId

return

GO
GRANT EXECUTE ON  [dbo].[vspPRAutoEarnsEmplList] TO [public]
GO
