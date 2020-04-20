SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRSalaryDistribEmplList]
/************************************************************************
* Created:	EN 02/09/07   
* Modified:    
*
* Usage:
*   Returns a list of active salary employees that will be skipped when posting  
*	salary distributions because they have entries in a timecard batch.
*
* Inputs:
*	@prco		PR Company #
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*
* Outputs:
*	resultset of active salary employees who are assigned an earnings code in bPREH
*   with bPREC Method of 'A' with earnings and entries in bPRTB
*
*************************************************************************/
    
    (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null)

as
set nocount on

select distinct b.Employee, isnull(h.LastName,'') + ', ' + isnull(h.FirstName,'')
	+ ' ' + isnull(h.MidName,'') + ' ' + isnull(h.Suffix,'') as [Name],	b.BatchId, c.InUseBy
from dbo.bPRTB b (nolock)
join dbo.bPREH h (nolock) on b.Co = h.PRCo and b.Employee = h.Employee
join dbo.bPREC e (nolock) on b.Co = e.PRCo and h.EarnCode = e.EarnCode
--join dbo.bPRAE a (nolock) on b.Co = a.PRCo and b.Employee = a.Employee
join dbo.bHQBC c (nolock) on b.Co = c.Co and b.Mth = c.Mth and b.BatchId = c.BatchId
where c.Co = @prco and c.PRGroup = @prgroup and c.PREndDate = @prenddate
	and h.ActiveYN = 'Y' and e.Method = 'A'
order by b.Employee, b.BatchId

return

GO
GRANT EXECUTE ON  [dbo].[bspPRSalaryDistribEmplList] TO [public]
GO
