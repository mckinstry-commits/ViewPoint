SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLCloseMSHaulList]
/**************************************************
* Created: GG 01/31/01
* Modified: GG 08/04/06 - added nolock hints and order by clause
*
* Usage:
*   Called by GL Close Control form to list unprocessed
*   MS transactions with Hauler Payment amounts prior to closing a month.
*
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of unprocessed bMSTD entries
**************************************************/
(@glco bCompany = null, @mth bMonth = null)
as
set nocount on

select t.MSCo, t.Mth, t.MSTrans, t.HaulVendor, t.Ticket, t.HaulTrans
from bMSTD t (nolock)
join bMSCO c (nolock) on c.MSCo = t.MSCo
join bAPCO a (nolock) on a.APCo = c.APCo
where t.Mth <= @mth and t.PayTotal <> 0.00 and t.APRef is null and t.Void = 'N'
   and (c.GLCo = @glco or a.GLCo = @glco)
order by t.MSCo, t.Mth, t.MSTrans

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseMSHaulList] TO [public]
GO
