SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[SLCBGrid]
   /***************************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - #26761 comments,with nolock
   *					MV 02/23/05 - #26761 top 100 percent, order by
   *	Used by:		SL Change Order Form
   ****************************************/
    as
    select top 100 percent a.Co, a.Mth, a.BatchId, a.BatchSeq, a.BatchTransType,
    	a.SLTrans, a.SL, a.SLItem, a.ActDate, a.SLChangeOrder, a.AppChangeOrder, a.Description,
    	a.UM, a.ChangeCurUnits, a.ChangeCurCost
    	/*, 'ChgCur' = Case when b.UM = "LS" then a.ChangeCurCost else a.ChangeCurUnits end */
    	from SLCB a with (nolock)
    	inner join SLIT b with (nolock) on b.SLCo=a.Co and b.SL=a.SL and b.SLItem=a.SLItem
   	order by a.Co, a.Mth, a.BatchId, a.BatchSeq

GO
GRANT SELECT ON  [dbo].[SLCBGrid] TO [public]
GRANT INSERT ON  [dbo].[SLCBGrid] TO [public]
GRANT DELETE ON  [dbo].[SLCBGrid] TO [public]
GRANT UPDATE ON  [dbo].[SLCBGrid] TO [public]
GO
