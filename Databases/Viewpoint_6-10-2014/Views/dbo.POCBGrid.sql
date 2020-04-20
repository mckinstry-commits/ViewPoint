SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      view [dbo].[POCBGrid] 
   /**************************************************
   *	Created by:		??
   *	Modified by:	10/27/03 MV - #22320 change ChgBO to ChgCost
   *					01/21/05 MV - #26761 with (nolock)
   *					02/23/05 MV - #26761 top 100 percent, order by
   *	Used by:		Form PO Change Orders
   ****************************************************/
   as 
   select top 100 percent a.Co, a.Mth, a.BatchId, a.BatchSeq, a.POTrans, a.PO,
    	a.POItem, a.ChangeOrder, a.ActDate, a.Description, a.UM, a.BatchTransType,
    	'ChgCur' = Case when b.UM = 'LS' then 0 else a.ChangeCurUnits end,
    	'ChgCost' = a.ChgTotCost
    	from POCB a with (nolock)
    	inner join POIT b with (nolock) on b.POCo=a.Co and b.PO=a.PO and b.POItem=a.POItem
   	order by a.Co, a.Mth, a.BatchId, a.BatchSeq
    
    /*ALTER   view POCBGrid as select a.Co, a.Mth, a.BatchId, a.BatchSeq, a.POTrans, a.PO,
    	a.POItem, a.ChangeOrder, a.ActDate, a.Description, a.UM, a.BatchTransType,
    	'ChgCur' = Case when b.UM = "LS" then a.ChangeCurCost else a.ChangeCurUnits end,
    	'ChgBO' = Case when b.UM = "LS" then a.ChangeBOCost else a.ChangeBOUnits end
    	from POCB a
    	inner join POIT b on b.POCo=a.Co and b.PO=a.PO and b.POItem=a.POItem*/


GO
GRANT SELECT ON  [dbo].[POCBGrid] TO [public]
GRANT INSERT ON  [dbo].[POCBGrid] TO [public]
GRANT DELETE ON  [dbo].[POCBGrid] TO [public]
GRANT UPDATE ON  [dbo].[POCBGrid] TO [public]
GRANT SELECT ON  [dbo].[POCBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCBGrid] TO [Viewpoint]
GO
