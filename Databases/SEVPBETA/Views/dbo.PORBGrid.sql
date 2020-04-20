SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   view [dbo].[PORBGrid]
   /***************************************
   *	Created by:		??
   *	Modified by:	MV 01/21/05 - #26761 comments, with (nolocks)
   *					MV 02/23/05 - #26761 top 100 percent, order by
   *					GF 08/22/2011 - TK-07879 PO ITEM LINE
   *
   *	Used by:		Form PO Receipts 
   ****************************************/
    as
    select top 100 percent a.Co, a.Mth, a.BatchId, a.BatchSeq, a.POTrans, a.PO,
    ----TK-07879
    	a.POItem, a.POItemLine, a.RecvdDate, a.RecvdBy, a.Description, a.BatchTransType,
    	'ChgRecv' = Case when b.UM = 'LS' then a.RecvdCost else a.RecvdUnits end,
    	'ChgBO' = Case when b.UM = 'LS' then a.BOCost else a.BOUnits end, a.Receiver#
    	from PORB a with (nolock)
    	inner join POIT b with (nolock) on b.POCo=a.Co and b.PO=a.PO and b.POItem=a.POItem
   	order by a.Co,a.Mth,a.BatchId, a.BatchSeq



GO
GRANT SELECT ON  [dbo].[PORBGrid] TO [public]
GRANT INSERT ON  [dbo].[PORBGrid] TO [public]
GRANT DELETE ON  [dbo].[PORBGrid] TO [public]
GRANT UPDATE ON  [dbo].[PORBGrid] TO [public]
GO
