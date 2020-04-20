SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLCloseMSMatlVendorList]
/**************************************************
* Created:	GF 03/01/2005
* Modified: GF 07/19/2005 - issue #29318 do not check for material vendor payments
*			GF 09/02/2005 - issue #29303 changed to summary of tickets by month for material vendor.
*			GG 07/31/06 - #29303 - restore original resultset, but limit to top 500 rows, add nolock and order by clause
*
*
* Usage:
*   Called by GL Close Control form to list unprocessed
*   MS transactions with Material Vendor Payment amounts prior to closing a month.
*	Not required for close, but some sites may want to see what has yet to be expensed.
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

-- return first 500 MS Tickets with Material Vendors that have not been invoiced in AP
select top 500 t.MSCo, t.Mth, t.MSTrans, t.MatlVendor, t.Ticket
from dbo.bMSTD t (nolock)
join dbo.bMSCO c (nolock) on c.MSCo = t.MSCo
join dbo.bAPCO a (nolock) on a.APCo = c.APCo
where t.Mth <= @mth and t.MatlVendor is not null and t.MatlAPRef is null and t.Void = 'N'
and t.MatlUnits <> 0 and (c.GLCo = @glco or a.GLCo = @glco) 
order by t.MSCo, t.Mth, t.MSTrans

return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseMSMatlVendorList] TO [public]
GO
