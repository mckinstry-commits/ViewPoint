SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/************************************************/
CREATE view [dbo].[MSTDHaulGrid]
/**************************************************
 * Created: ??
 * Modified:	GG 2/15/05 - #26761 - added comments, (nolock) hints, and 'order by' clause
 *				GF 09/11/2008 - note that this view is used in frmMSHaulEntryTics form bound via form code.
 *
 *
 * Provides a view of transaction information used to fill the grid for ticket
 * verification in the MS Hauler Time Sheet Entry form.
 *
 ***************************************************/
as

select top 100 percent a.MSCo, a.Mth, a.MSTrans, a.FromLoc, a.Ticket, a.SaleType, a.MatlGroup, a.Material,
			'MatlDesc' = b.Description, UM, MatlUnits, VerifyHaul
from MSTD a (nolock)
left JOIN HQMT b (nolock) ON b.MatlGroup=a.MatlGroup and b.Material=a.Material
where a.HaulerType in ('H','E') and a.HaulTrans is null
order by a.MSCo, a.Mth, a.MSTrans



GO
GRANT SELECT ON  [dbo].[MSTDHaulGrid] TO [public]
GRANT INSERT ON  [dbo].[MSTDHaulGrid] TO [public]
GRANT DELETE ON  [dbo].[MSTDHaulGrid] TO [public]
GRANT UPDATE ON  [dbo].[MSTDHaulGrid] TO [public]
GRANT SELECT ON  [dbo].[MSTDHaulGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSTDHaulGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSTDHaulGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSTDHaulGrid] TO [Viewpoint]
GO
