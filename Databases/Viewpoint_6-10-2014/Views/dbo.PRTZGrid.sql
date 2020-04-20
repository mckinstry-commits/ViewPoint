SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[PRTZGrid]
   /***************************************
   *	Created by:		??
   *	Modified by:	
   *	Used by:		forms PRTimeCards, PRAutoOT, and PRPostAutoEarns to return 
   *   				batch header info, PRGroup, and PREndDate for all batchs where Source="PR Entry"
   ****************************************/
    as select HQBC.Co, HQBC.Mth, HQBC.BatchId, HQBC.PRGroup, HQBC.PREndDate
    	from HQBC with (nolock)
   	left join PRTB with (nolock) on HQBC.Co=PRTB.Co and HQBC.Mth=PRTB.Mth and HQBC.BatchId=PRTB.BatchId
    	where Source='PR Entry'

GO
GRANT SELECT ON  [dbo].[PRTZGrid] TO [public]
GRANT INSERT ON  [dbo].[PRTZGrid] TO [public]
GRANT DELETE ON  [dbo].[PRTZGrid] TO [public]
GRANT UPDATE ON  [dbo].[PRTZGrid] TO [public]
GRANT SELECT ON  [dbo].[PRTZGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTZGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTZGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTZGrid] TO [Viewpoint]
GO
