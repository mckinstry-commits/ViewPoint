SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRCheckList]
/************************************************************************
* Created:	GG 02/12/07   
* Modified:  
*
* Usage:
*   Returns a list of check information to display in the PR Check Print form.
*
* Inputs:
*	@prco		PR Company #
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*	@beginchk	Beginning Check #
*	@endchk		Ending Check #
*
* Outputs:
*	resultset of check info 
*
*************************************************************************/
    
    (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
	 @beginchk bCMRef = null, @endchk bCMRef = null)

as
set nocount on

-- use outer join to CMDT because checks may not have been updated to CM yet
select e.Employee, isnull(e.LastName,'') + ', ' + isnull(e.FirstName,'')
	+ ' ' + isnull(e.MidName,'') + ' ' + isnull(e.Suffix,'') as [Name],
	s.PaySeq, s.CMRef
from dbo.bPRSQ s (nolock)
join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
left join dbo.bCMDT c (nolock) on c.CMCo = s.CMCo and c.CMAcct = s.CMAcct and c.CMTransType = 1 and c.CMRef = s.CMRef and c.CMRefSeq = s.CMRefSeq
where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate
	and s.PayMethod = 'C' and s.ChkType = 'C' and c.StmtDate is null	-- exclude entries already cleared in CM
	and s.CMRef >= isnull(@beginchk,'') and s.CMRef <= isnull(@endchk,'~~~~~~~~~~')
order by s.CMRef

return

GO
GRANT EXECUTE ON  [dbo].[vspPRCheckList] TO [public]
GO
