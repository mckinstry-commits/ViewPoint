SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[POIBPost] 
   /*******************************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - with (nolock)
   *	Used by:	?? PO batch posting?
   ********************************************/
   as
    select i.* , isnull(t.OrigUnits,0) as [POITOrigUnits], isnull(t.OrigUnitCost,0) as [POITOrigUnitCost],
		isnull(t.OrigECM,'') as [POITOrigECM], isnull(t.OrigCost,0) as [POITOrigCost], isnull(t.OrigTax,0) as [POITOrigTax],
		isnull(t.CurUnits,0) as [CurUnits], isnull(t.CurUnitCost,0) as [CurUnitCost], isnull(t.CurECM,'') as [CurECM],
		isnull(t.CurCost,0) as [CurCost],isnull(t.CurTax,0) as [CurTax], isnull(t.RecvdUnits,0) as [RecvdUnits],
		isnull(t.RecvdCost,0) as [RecvdCost], isnull(t.BOUnits,0) as [BOUnits], isnull(t.BOCost,0) as [BOCost],
		isnull(t.TotalUnits,0) as [TotalUnits], isnull(t.TotalCost,0) as [TotalCost], isnull(t.TotalTax,0) as [TotalTax],
		isnull(t.InvUnits,0) as [InvUnits], isnull(t.InvCost,0) as [InvCost], isnull(t.InvTax,0) as [InvTax],
		isnull(t.RemUnits,0) as [RemUnits], isnull(t.RemCost,0) as [RemCost], isnull(t.RemTax,0) as [RemTax]
       from POIB i with (nolock)
       join POHB h with (nolock) on i.Co=h.Co and i.Mth=h.Mth and i.BatchId=h.BatchId and i.BatchSeq=h.BatchSeq
       full Outer join POIT t with (nolock) on h.Co=t.POCo and h.PO=t.PO and i.POItem=t.POItem

GO
GRANT SELECT ON  [dbo].[POIBPost] TO [public]
GRANT INSERT ON  [dbo].[POIBPost] TO [public]
GRANT DELETE ON  [dbo].[POIBPost] TO [public]
GRANT UPDATE ON  [dbo].[POIBPost] TO [public]
GO
