SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLClosePRPayPdsList]
/**************************************************
* Created: GG 11/30/99
* Modified: GG 08/04/06 - added nolock hints and order by clause
* JVH 7/11/12 - added work completed GLCo
*
* Usage:
*   Called by GL Close Control form to list PR Pay Periods
*   that have not had their final updates run prior to closing a month.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of unfinished PR Pay Periods
**************************************************/
(@glco bCompany, @mth bMonth)
as
set nocount on

select distinct p.PRCo, p.PRGroup, p.PREndDate, p.JCInterface,
   p.EMInterface, p.GLInterface, p.APInterface
from bPRPC p (nolock)
join bPRCO c (nolock) on c.PRCo = p.PRCo
left join bPRTH t (nolock) on t.PRCo = p.PRCo and t.PRGroup = p.PRGroup and t.PREndDate = p.PREndDate
LEFT JOIN dbo.vSMWorkCompleted ON t.PRCo = vSMWorkCompleted.CostCo AND t.PRGroup = vSMWorkCompleted.PRGroup AND t.PREndDate = vSMWorkCompleted.PREndDate AND t.Employee = vSMWorkCompleted.PREmployee AND t.PaySeq = vSMWorkCompleted.PRPaySeq AND t.PostSeq = vSMWorkCompleted.PRPostSeq
LEFT JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID
where (p.BeginMth <= @mth or isnull(p.EndMth,p.BeginMth) <= @mth)
   and (c.GLCo = @glco or isnull(t.GLCo,0) = @glco OR vSMWorkCompletedDetail.GLCo = @glco)
   and (p.JCInterface = 'N' or p.EMInterface = 'N' or p.GLInterface = 'N' or p.APInterface = 'N')
order by p.PRCo, p.PRGroup, p.PREndDate

return

GO
GRANT EXECUTE ON  [dbo].[bspGLClosePRPayPdsList] TO [public]
GO
