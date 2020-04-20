SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLCloseAPUnapprovedList]
/**************************************************
* Created: GG 11/30/99
* Modified: GG 08/04/06 - added nolock hints and order by clause
*
* Usage:
*   Called by GL Close Control form to list unprocessed AP
*   Unapproved invoices prior to closing a month.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of unprocessed unapproved invoices
**************************************************/
(@glco bCompany, @mth bMonth)
as
set nocount on

select distinct u.APCo, u.UIMth, u.UISeq, u.Vendor, u.Description
from bAPUI u (nolock)
join bAPCO a (nolock) on a.APCo = u.APCo
left join bAPUL l (nolock) on l.APCo = u.APCo and l.UIMth = u.UIMth and l.UISeq = u.UISeq
where u.UIMth <= @mth and (a.GLCo = @glco or isnull(l.GLCo,0) = @glco)
order by u.APCo, u.UIMth, u.UISeq

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseAPUnapprovedList] TO [public]
GO
