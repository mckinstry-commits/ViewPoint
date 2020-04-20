SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Subcontract detail
   * used in lookups for distinct PMSL.SubCo's
   *
   *****************************************/
    
   CREATE view [dbo].[PMSLSubCoLookup] as select a.SLCo,a.SL,a.SLChangeOrder,b.Description
   from dbo.SLCD a
   inner join dbo.SLIT b on b.SLCo=a.SLCo and b.SL=a.SL and b.SLItem=a.SLItem
   where a.SLChangeOrder is not null and a.SLChangeOrder <> 0
   Group by a.SLCo,a.SL,a.SLChangeOrder,b.Description
   union
   select c.SLCo,c.SL,c.SubCO,c.SLItemDescription
   from dbo.PMSL c
   where not exists(select * from dbo.SLCD d where c.SLCo=d.SLCo and c.SL=d.SL and c.SubCO=d.SLChangeOrder)
   and c.SL is not null and c.SubCO is not null and c.SubCO <> 0
   Group by c.SLCo,c.SL,c.SubCO,c.SLItemDescription

GO
GRANT SELECT ON  [dbo].[PMSLSubCoLookup] TO [public]
GRANT INSERT ON  [dbo].[PMSLSubCoLookup] TO [public]
GRANT DELETE ON  [dbo].[PMSLSubCoLookup] TO [public]
GRANT UPDATE ON  [dbo].[PMSLSubCoLookup] TO [public]
GRANT SELECT ON  [dbo].[PMSLSubCoLookup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSLSubCoLookup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSLSubCoLookup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSLSubCoLookup] TO [Viewpoint]
GO
