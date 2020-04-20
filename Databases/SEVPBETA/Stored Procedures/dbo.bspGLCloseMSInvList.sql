SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLCloseMSInvList]
/**************************************************
* Created: GG 01/31/01
* Modified: GG 01/14/02 - #15798 - exclude uninvoiced interco sales prior to last close
*			GG 08/04/06 - added nolock hints and order by clause
*
* Usage:
*   Called by GL Close Control form to list uninvoiced
*   MS transactions prior to closing a month.
*
*   Includes all customer sales and intercompany job and
*   inventory sales if using the intercompany invoicing option.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of uninvoiced bMSTD entries
**************************************************/
(@glco bCompany = null, @mth bMonth = null)
as
set nocount on

declare @lastsubclsd bMonth

-- get Last Month SubLedgers Closed
select @lastsubclsd = LastMthSubClsd
from bGLCO where GLCo = @glco

-- uninvoiced Customer Sales
select t.MSCo, t.Mth, t.MSTrans, t.Customer, t.Ticket, t.HaulTrans
from bMSTD t (nolock)
join bMSCO c (nolock) on c.MSCo = t.MSCo
join bARCO a (nolock) on a.ARCo = c.ARCo
where t.Mth <= @mth and t.Customer is not null and t.MSInv is null and t.Void = 'N'
   and (c.GLCo = @glco or a.GLCo = @glco)
union
-- uninvoiced intercompany Job sales
select t.MSCo, t.Mth, t.MSTrans, h.Customer, t.Ticket, t.HaulTrans
from bMSTD t (nolock)
join bMSCO c (nolock) on c.MSCo = t.MSCo
join bJCCO j (nolock) on j.JCCo = t.JCCo
join bHQCO h (nolock) on h.HQCo = t.JCCo
where t.Mth <= @mth and t.MSInv is null and t.Void = 'N'
   and (c.GLCo = @glco or j.GLCo = @glco) and c.GLCo <> j.GLCo and c.InterCoInv = 'Y'
and ((@lastsubclsd is not null and t.Mth > @lastsubclsd) or @lastsubclsd is null)	-- exclude sales in month's prior to last close
union
-- uninvoiced intercompany Inventory sales
select t.MSCo, t.Mth, t.MSTrans, h.Customer, t.Ticket, t.HaulTrans
from bMSTD t (nolock)
join bMSCO c (nolock) on c.MSCo = t.MSCo
join bINCO i (nolock) on i.INCo = t.INCo
join bHQCO h (nolock) on h.HQCo = t.INCo
where t.Mth <= @mth and t.MSInv is null and t.Void = 'N'
   and (c.GLCo = @glco or i.GLCo = @glco) and c.GLCo <> i.GLCo and c.InterCoInv = 'Y'
and ((@lastsubclsd is not null and t.Mth > @lastsubclsd) or @lastsubclsd is null)	-- exclude sales in month's prior to last close
order by t.MSCo, t.Mth, t.MSTrans

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseMSInvList] TO [public]
GO
