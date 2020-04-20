SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Material Detail used
   * in PM Material form for lookup on PO items
   *
   *****************************************/
   
   CREATE view [dbo].[PMMFPOItemLookup] as 
   select a.POCo, a.PO, a.POItem, MIN(a.Description) AS [Description]
   from dbo.POIT a
   Group by a.POCo, a.PO, a.POItem ----, a.Description
   union
   select b.POCo, b.PO, b.POItem, MIN(b.MtlDescription) AS [Descripiton]
   from dbo.PMMF b
   where not exists(select * from POIT c where c.POCo=b.POCo and c.PO=b.PO and c.POItem=b.POItem)
   Group by b.POCo, b.PO, b.POItem ----, b.MtlDescription




GO
GRANT SELECT ON  [dbo].[PMMFPOItemLookup] TO [public]
GRANT INSERT ON  [dbo].[PMMFPOItemLookup] TO [public]
GRANT DELETE ON  [dbo].[PMMFPOItemLookup] TO [public]
GRANT UPDATE ON  [dbo].[PMMFPOItemLookup] TO [public]
GO
