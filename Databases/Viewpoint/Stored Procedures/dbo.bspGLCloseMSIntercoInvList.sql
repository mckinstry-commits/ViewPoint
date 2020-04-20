SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLCloseMSIntercoInvList]
/**************************************************
* Created: GG 08/14/01
* Modified: GG 08/04/06 - add nolock hints
*			GG 07/25/07 - #123871 - corrected joins to JCCO and INCO  
*
* Usage:
*   Called by GL Close Control form to list MS intercompany invoices
*   that should be posted prior to closing a month.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of intercompany invoice header info from bMSII
**************************************************/
(@glco bCompany = null, @mth bMonth = null)
as
set nocount on

-- unposted Intercompany Invoices
select distinct m.MSCo, m.Mth, m.MSInv, m.SoldToCo, m.InvDate
from bMSII m (nolock)
join bMSIX x (nolock) on x.MSCo = m.MSCo and x.MSInv = m.MSInv
left join bJCCO j (nolock) on j.JCCo = x.JCCo
left join bINCO i (nolock) on i.INCo = x.INCo			
where m.Mth <= @mth and (j.GLCo = @glco or i.GLCo = @glco)
order by m.MSCo, m.Mth, m.MSInv

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseMSIntercoInvList] TO [public]
GO
