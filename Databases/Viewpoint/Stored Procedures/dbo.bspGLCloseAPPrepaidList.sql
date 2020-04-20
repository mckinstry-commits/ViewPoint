SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLCloseAPPrepaidList]
/**************************************************
* Created: GG 11/30/99
* Modified:	MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 08/04/06 - added nolock hints and order by clause
*
* Usage:
*   Called by GL Close Control form to list unprocessed AP
*   Prepaid transactions prior to closing a month.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*
* Output:
*   none
*
* Return:
*   recordset of unprocessed prepaids
**************************************************/
(@glco bCompany, @mth bMonth)
as
set nocount on

select h.APCo, h.Mth, h.APTrans, h.Vendor, h.Description, h.PrePaidChk
from bAPTH h (nolock)
join bAPCO a (nolock) on a.APCo = h.APCo
join bCMCO c (nolock) on c.CMCo = h.CMCo
where h.PrePaidYN = 'Y' and h.PrePaidProcYN = 'N' and isnull(h.PrePaidMth,'') <= @mth
   and (a.GLCo = @glco or c.GLCo = @glco)
order by h.APCo, h.Mth, h.APTrans

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseAPPrepaidList] TO [public]
GO
