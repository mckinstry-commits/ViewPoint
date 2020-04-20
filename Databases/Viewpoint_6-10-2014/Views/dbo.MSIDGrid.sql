SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIDGrid]
   /**************************************************
   * Created: ??
   * Modified: GG 2/15/05 - #26761 - added comments, (nolock) hints, and 'order by' clause
   *
   * Provides a view of ticket detail used to fill the grid on
   * the MS Invoice Edit form.
   *
   ***************************************************/
   as
   select top 100 percent a.Co, a.Mth, a.BatchId, a.BatchSeq, a.MSTrans, a.Ticket, a.CustJob,
        a.CustPO, a.SaleDate, 'Date' = b.SaleDate, a.FromLoc, 'Location' = b.FromLoc,
        a.MatlGroup, a.Material, a.UM, b.MatlUnits, a.UnitPrice, b.ECM,b.HaulTotal,
        b.TaxTotal, 'Total' = isnull(b.MatlTotal,0) + isnull(b.HaulTotal,0) + isnull(b.TaxTotal,0),
        'Discount' = isnull(b.DiscOff,0) + isnull(b.TaxDisc,0)
   from MSID a with (nolock)
   join MSTD b with (nolock) ON b.MSCo = a.Co and b.Mth = a.Mth and b.MSTrans = a.MSTrans
   order by a.Co, a.Mth, a.BatchId, a.BatchSeq, a.MSTrans

GO
GRANT SELECT ON  [dbo].[MSIDGrid] TO [public]
GRANT INSERT ON  [dbo].[MSIDGrid] TO [public]
GRANT DELETE ON  [dbo].[MSIDGrid] TO [public]
GRANT UPDATE ON  [dbo].[MSIDGrid] TO [public]
GRANT SELECT ON  [dbo].[MSIDGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSIDGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSIDGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSIDGrid] TO [Viewpoint]
GO
