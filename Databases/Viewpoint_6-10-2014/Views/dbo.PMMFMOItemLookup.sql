SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Material Detail used
   * in PM Material form for lookup on MO items
   *
   *****************************************/
   
   CREATE view [dbo].[PMMFMOItemLookup] as 
   select a.INCo, a.MO, a.MOItem, MIN(a.Description) AS [Description]
   from dbo.INMI a
   Group by a.INCo, a.MO, a.MOItem ----, a.Description
   union
   select b.INCo, b.MO, b.MOItem, MIN(b.MtlDescription) AS [Description]
   from dbo.PMMF b
   where not exists(select * from dbo.INMI c where c.INCo=b.INCo and c.MO=b.MO and c.MOItem=b.MOItem)
   and b.MOItem is not null
   Group by b.INCo, b.MO, b.MOItem ----, b.MtlDescription



GO
GRANT SELECT ON  [dbo].[PMMFMOItemLookup] TO [public]
GRANT INSERT ON  [dbo].[PMMFMOItemLookup] TO [public]
GRANT DELETE ON  [dbo].[PMMFMOItemLookup] TO [public]
GRANT UPDATE ON  [dbo].[PMMFMOItemLookup] TO [public]
GRANT SELECT ON  [dbo].[PMMFMOItemLookup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMMFMOItemLookup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMMFMOItemLookup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMMFMOItemLookup] TO [Viewpoint]
GO
